# 🗳️ Sistema de Votación Descentralizado - Smart Contract

![Solidity](https://img.shields.io/badge/Solidity-0.8.20-363636?logo=solidity)
![Ethereum](https://img.shields.io/badge/Ethereum-Sepolia-3C3C3D?logo=ethereum)
![License](https://img.shields.io/badge/License-MIT-blue.svg)

## 📋 Descripción

Sistema de votación descentralizado construido en Solidity que permite gestionar procesos electorales completos de forma segura, transparente y auditable en la blockchain de Ethereum.

## 🎯 Características Principales

### 🛡️ Seguridad y Transparencia
- **Voto único por persona** - Prevención de votos duplicados
- **Control de acceso** - Solo votantes autorizados pueden participar
- **Resultados inmutables** - Una vez finalizada, la elección no puede ser alterada
- **Auditoría completa** - Todos los eventos son registrados en blockchain

### 🔄 Ciclo Electoral Completo
1. **📝 Fase de Registro** - Configuración de candidatos y votantes
2. **✅ Período de Votación** - Emisión segura de votos
3. **🏁 Elección Finalizada** - Resultados definitivos y transparentes

### 🎁 Funcionalidades Avanzadas
- **Delegación de votos** - Transferencia de derecho de voto
- **Consultas públicas** - Cualquiera puede verificar resultados
- **Eventos en tiempo real** - Notificaciones de todas las acciones importantes

## 📊 Estructura del Contrato

### Roles del Sistema
- **👑 Administrador** - Despliega el contrato y gestiona el proceso
- **🗳️ Votantes** - Direcciones autorizadas para votar
- **📊 Candidatos** - Opciones disponibles en la elección

### Estados de la Elección
```solidity
enum ElectionState {
    REGISTRATION,  // Fase de configuración
    VOTING,        // Votación activa
    FINISHED       // Resultados finales
}
