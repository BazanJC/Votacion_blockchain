// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

contract VotingSystem {
    struct Candidate {
        string name;
        uint256 voteCount;
        bool exists;
    }

    struct Voter {
        bool isAuthorized;
        bool hasVoted;
        address delegatedTo;
        uint256 weight;
    }
    

    enum ElectionState {
        REGISTRATION,  // Fase de registro de candidatos y votantes
        VOTING,        // Fase activa de votación
        FINISHED       // Elección finalizada
    }
    
    // Dirección del administrador electoral (quien despliega el contrato)
    address public admin;
    
    // Estado actual de la elección
    ElectionState public electionState;
    
    // Mapeo de candidatos (ID => Candidate)
    mapping(uint256 => Candidate) public candidates;
    
    // Mapeo de votantes (address => Voter)
    mapping(address => Voter) public voters;
    
    // Array para almacenar IDs de candidatos
    uint256[] public candidateIds;
    
    // Contadores
    uint256 public totalVotes;
    uint256 public totalVoters;
    uint256 public nextCandidateId;
    
    // Ganador de la elección
    uint256 public winnerCandidateId;

    event CandidateAdded(uint256 indexed candidateId, string name);
    
    event VoterAuthorized(address indexed voter);

    event VoteCast(address indexed voter, uint256 indexed candidateId);

    event VoteDelegated(address indexed from, address indexed to);
    

    event ElectionStateChanged(ElectionState newState);

    event WinnerDeclared(uint256 indexed candidateId, string candidateName, uint256 voteCount);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Solo el administrador puede ejecutar esta accion");
        _;
    }
    

    modifier onlyInState(ElectionState _state) {
        require(electionState == _state, "Estado de eleccion incorrecto para esta accion");
        _;
    }

    modifier onlyAuthorizedVoter() {
        require(voters[msg.sender].isAuthorized, "Votante no autorizado");
        _;
    }

    constructor() {
        admin = msg.sender;
        electionState = ElectionState.REGISTRATION;
        nextCandidateId = 1;
        
        emit ElectionStateChanged(ElectionState.REGISTRATION);
    }

    function addCandidate(string memory _name) 
        external 
        onlyAdmin 
        onlyInState(ElectionState.REGISTRATION) 
        returns (uint256) 
    {
        require(bytes(_name).length > 0, "El nombre del candidato no puede estar vacio");
        
        uint256 candidateId = nextCandidateId;
        candidates[candidateId] = Candidate({
            name: _name,
            voteCount: 0,
            exists: true
        });
        
        candidateIds.push(candidateId);
        nextCandidateId++;
        
        emit CandidateAdded(candidateId, _name);
        return candidateId;
    }
    

    function authorizeVoter(address _voterAddress) 
        external 
        onlyAdmin 
        onlyInState(ElectionState.REGISTRATION) 
    {
        require(_voterAddress != address(0), "Direccion de votante invalida");
        require(!voters[_voterAddress].isAuthorized, "Votante ya autorizado");
        
        voters[_voterAddress] = Voter({
            isAuthorized: true,
            hasVoted: false,
            delegatedTo: address(0),
            weight: 1
        });
        
        totalVoters++;
        
        emit VoterAuthorized(_voterAddress);
    }

    function startVoting() 
        external 
        onlyAdmin 
        onlyInState(ElectionState.REGISTRATION) 
    {
        require(candidateIds.length > 0, "Debe haber al menos un candidato");
        require(totalVoters > 0, "Debe haber al menos un votante autorizado");
        
        electionState = ElectionState.VOTING;
        emit ElectionStateChanged(ElectionState.VOTING);
    }

    function finishElection() 
        external 
        onlyAdmin 
        onlyInState(ElectionState.VOTING) 
    {
        electionState = ElectionState.FINISHED;
        
        // Encontrar al ganador
        uint256 winningVoteCount = 0;
        uint256 winningCandidateId = 0;
        
        for (uint256 i = 0; i < candidateIds.length; i++) {
            uint256 candidateId = candidateIds[i];
            if (candidates[candidateId].voteCount > winningVoteCount) {
                winningVoteCount = candidates[candidateId].voteCount;
                winningCandidateId = candidateId;
            }
        }
        
        winnerCandidateId = winningCandidateId;
        
        if (winningCandidateId != 0) {
            emit WinnerDeclared(
                winningCandidateId, 
                candidates[winningCandidateId].name, 
                winningVoteCount
            );
        }
        
        emit ElectionStateChanged(ElectionState.FINISHED);
    }

    function vote(uint256 _candidateId) 
        external 
        onlyAuthorizedVoter 
        onlyInState(ElectionState.VOTING) 
    {
        Voter storage sender = voters[msg.sender];
        require(!sender.hasVoted, "Ya has votado");
        require(candidates[_candidateId].exists, "Candidato no existe");
        
        // Registrar el voto
        sender.hasVoted = true;
        candidates[_candidateId].voteCount += sender.weight;
        totalVotes += sender.weight;
        
        emit VoteCast(msg.sender, _candidateId);
    }
    
    function delegateVote(address _to) 
        external 
        onlyAuthorizedVoter 
        onlyInState(ElectionState.VOTING) 
    {
        Voter storage sender = voters[msg.sender];
        require(!sender.hasVoted, "Ya has votado, no puedes delegar");
        require(_to != msg.sender, "No puedes delegar tu voto a ti mismo");
        require(voters[_to].isAuthorized, "Solo puedes delegar a un votante autorizado");
        
        // Evitar bucles de delegación
        address current = _to;
        while (voters[current].delegatedTo != address(0)) {
            current = voters[current].delegatedTo;
            require(current != msg.sender, "Bucle de delegacion detectado");
        }
        
        sender.hasVoted = true;
        sender.delegatedTo = _to;
        
        if (voters[_to].hasVoted) {
            // Si el destinatario ya votó, sumar el voto a su candidato
            // En una implementación real necesitaríamos trackear esto
            voters[_to].weight += sender.weight;
        } else {
            // Si no ha votado, incrementar su peso para cuando vote
            voters[_to].weight += sender.weight;
        }
        
        emit VoteDelegated(msg.sender, _to);
    }

    function getCandidate(uint256 _candidateId) 
        external 
        view 
        returns (string memory name, uint256 voteCount, bool exists) 
    {
        Candidate memory candidate = candidates[_candidateId];
        return (candidate.name, candidate.voteCount, candidate.exists);
    }

    function getVoter(address _voterAddress) 
        external 
        view 
        returns (bool isAuthorized, bool hasVoted, address delegatedTo, uint256 weight) 
    {
        Voter memory voter = voters[_voterAddress];
        return (voter.isAuthorized, voter.hasVoted, voter.delegatedTo, voter.weight);
    }

    function getAllCandidateIds() external view returns (uint256[] memory) {
        return candidateIds;
    }

    function getCandidateCount() external view returns (uint256) {
        return candidateIds.length;
    }
    
    function getWinner() 
        external 
        view 
        returns (uint256 candidateId, string memory name, uint256 voteCount, bool exists) 
    {
        require(electionState == ElectionState.FINISHED, "Eleccion no finalizada");
        require(winnerCandidateId != 0, "No hay ganador declarado");
        
        Candidate memory winner = candidates[winnerCandidateId];
        return (winnerCandidateId, winner.name, winner.voteCount, winner.exists);
    }

    function getElectionResults() 
        external 
        view 
        returns (string[] memory names, uint256[] memory votes) 
    {
        require(electionState == ElectionState.FINISHED, "Eleccion no finalizada");
        
        uint256 candidateCount = candidateIds.length;
        names = new string[](candidateCount);
        votes = new uint256[](candidateCount);
        
        for (uint256 i = 0; i < candidateCount; i++) {
            uint256 candidateId = candidateIds[i];
            names[i] = candidates[candidateId].name;
            votes[i] = candidates[candidateId].voteCount;
        }
        
        return (names, votes);
    }

    function getElectionStateString() external view returns (string memory) {
        if (electionState == ElectionState.REGISTRATION) return "REGISTRO";
        if (electionState == ElectionState.VOTING) return "VOTACION";
        if (electionState == ElectionState.FINISHED) return "FINALIZADA";
        return "DESCONOCIDO";
    }
}