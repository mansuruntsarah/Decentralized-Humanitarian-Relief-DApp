# Decentralized Humanitarian Aid & Relief Escrow (DApp)

A full-stack Web3 Decentralized Application designed to bring absolute transparency and security to humanitarian aid funding. This platform connects Donors, Relief Agencies, and a UN Arbiter through a secure, smart-contract-based escrow system.

## Key Features

* **Role-Based Access Control (RBAC):** Customized dashboards for Donors, Relief Agencies, and the UN Arbiter, authenticated directly via MetaMask.
* **100% On-Chain Data:** Adhering to strict decentralized architecture, no off-chain databases (SQL/MongoDB) are used. All user profiles, reputation scores, and mission details are queried directly from the Ethereum blockchain.
* **Global Relief Feed:** Dynamic frontend filtering and sorting to prioritize critical missions by maximum budget and region.
* **Smart Contract Escrow:** Donors lock funds into a trustless escrow that only pays out upon verified delivery, with automated operational tax calculations.
* **Automated Dispute Resolution:** A dedicated UN Arbiter panel to penalize fraudulent agencies or refund donors in the event of disputed deliveries.
* **Real-Time UI Updates:** Event listeners automatically refresh the interface when a blockchain transaction (like a pledge or delivery) is confirmed.

## Tech Stack

* **Smart Contracts:** Solidity
* **Blockchain Environment:** Ganache (Local), Truffle Suite
* **Frontend:** HTML/CSS/JS, React
* **Web3 Integration:** Web3.js / Ethers.js, MetaMask

## How to Run the Project Locally

### Prerequisites
* [Node.js](https://nodejs.org/) installed
* [Ganache](https://trufflesuite.com/ganache/) installed and running
* [MetaMask](https://metamask.io/) extension installed in your browser

### Installation Steps

1. **Clone the repository:**
   ```bash
   git clone [https://github.com/YourUsername/decentralized-aid-escrow.git](https://github.com/YourUsername/decentralized-aid-escrow.git)
   cd decentralized-aid-escrow
