// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract HumanitarianAidEscrow {

    enum Role { arbiter, donor, agency }

    enum MissionStatus { Pending, Transit, Delivered, Disputed, Resolved }

    struct User {
        string name;
        Role role;
        address walletAddress;
        uint256 reputationScore;
        bool isRegistered;
    }

    struct Mission {
        uint256 missionId;
        string category;
        uint256 maxBudget;
        string region;
        address donor;
        MissionStatus status;
        address selectedAgency;
        uint256 approvedBid;
        uint256 escrowBalance;
        Pledge[] pledges;
    }

    struct Pledge {
        address agency;
        uint256 bidAmount;
        bool isActive;
    }


    address public immutable arbiter;

    mapping(address => User) public users;

    mapping(uint256 => Mission) public missions;

    mapping(uint256 => bool) public missionExists;

    event UserRegistered(address indexed wallet, string name, Role role);
    event DeliveryMarked(uint256 indexed missionId, address indexed agency);
    event DeliveryApproved(uint256 indexed missionId, uint256 payout, uint256 fee);
    event MissionPosted(uint256 indexed missionId, address indexed donor, string category);
    event PledgeSubmitted(uint256 indexed missionId, address indexed agency, uint256 bidAmount);
    event AgencySelected(uint256 indexed missionId, address indexed agency, uint256 approvedBid);
    event MissionDisputed(uint256 indexed missionId, address indexed donor);
    event DisputeResolved(uint256 indexed missionId, bool agencyFault);
    event FundsEscrowed(uint256 indexed missionId, uint256 amount);


    modifier onlyRegistered() {
        require(users[msg.sender].isRegistered, "Not registered");
        _;
    }

    modifier onlyRole(Role _role) {
        require(users[msg.sender].role == _role, "Unauthorized role");
        _;
    }

    modifier missionMustExist(uint256 _missionId) {
        require(missionExists[_missionId], "Mission does not exist");
        _;
    }

    constructor() {
        arbiter = msg.sender;
        users[msg.sender] = User({
            name: "arbiter",
            role: Role.arbiter,
            walletAddress: msg.sender,
            reputationScore: 0,
            isRegistered: true
        });
    }

    function registerUser(string calldata _name, Role _role) external {
        
        require(!users[msg.sender].isRegistered, "Wallet already registered");

        
        require(_role == Role.donor || _role == Role.agency, "Invalid role selection");

        
        uint256 startingReputation = 0;
 
        if (_role == Role.agency) {
            startingReputation = 100;
        }
        
        users[msg.sender] = User({
            name: _name,
            role: _role,
            walletAddress: msg.sender,
            reputationScore: startingReputation,
            isRegistered: true
        });

    }

    function postMission(
        uint256 _missionId,
        string calldata _category,
        uint256 _maxBudget,
        string calldata _region
    )
        external
        onlyRegistered
        onlyRole(Role.donor)
    {
        require(!missionExists[_missionId], "Mission ID already used");
        require(_maxBudget > 0, "Budget must be greater than zero");

       
        missionExists[_missionId] = true;

        Mission storage m = missions[_missionId];
        m.missionId   = _missionId;
        m.category    = _category;
        m.maxBudget   = _maxBudget;
        m.region      = _region;
        m.donor       = msg.sender;
        m.status      = MissionStatus.Pending;
        

    }

    function pledgeToDeliver(uint256 _missionId, uint256 _bidAmount)
        external
        onlyRegistered
        onlyRole(Role.agency)
        missionMustExist(_missionId)
    {
        Mission storage m = missions[_missionId];

        require(m.status == MissionStatus.Pending, "Mission not Pending");
        require(_bidAmount <= m.maxBudget, "Bid exceeds max budget");
        require(users[msg.sender].reputationScore >= 40, "Reputation too low to bid");

        
        m.pledges.push(Pledge({
            agency: msg.sender,
            bidAmount: _bidAmount,
            isActive: true
        }));

        emit PledgeSubmitted(_missionId, msg.sender, _bidAmount);
    }

    function selectAgency(uint256 _missionId, uint256 _pledgeIndex)
        external
        onlyRegistered
        onlyRole(Role.donor)
        missionMustExist(_missionId)
    {
        Mission storage m = missions[_missionId];

        require(m.donor == msg.sender, "Not the mission donor");
        require(m.status == MissionStatus.Pending, "Mission not Pending");
        require(_pledgeIndex < m.pledges.length, "Invalid pledge index");

        Pledge storage chosen = m.pledges[_pledgeIndex];
        require(chosen.isActive, "Pledge is not active");

        m.selectedAgency = chosen.agency;
        m.approvedBid    = chosen.bidAmount;

        emit AgencySelected(_missionId, chosen.agency, chosen.bidAmount);
    } //shadi

    function fundMission(uint256 _missionId)
        external
        payable
        onlyRegistered
        onlyRole(Role.donor)
        missionMustExist(_missionId)
    {
        Mission storage m = missions[_missionId];

        require(m.donor == msg.sender, "Not the mission donor");
        require(m.status == MissionStatus.Pending, "Mission not Pending");
        require(m.selectedAgency != address(0), "No agency selected yet");

       
        require(msg.value >= m.approvedBid, "Insufficient funds sent");

        
        uint256 excess = msg.value - m.approvedBid;

        
        m.escrowBalance = m.approvedBid;

        
        m.status = MissionStatus.Transit;

        
        if (excess > 0) {
            (bool refunded, ) = payable(msg.sender).call{value: excess}("");
            require(refunded, "Refund failed");
        }

    }

    function markDelivered(uint256 _missionId)
        external
        onlyRegistered
        onlyRole(Role.agency)
        missionMustExist(_missionId)
    {
        Mission storage m = missions[_missionId];

        require(m.status == MissionStatus.Transit, "Mission not Transit");
        require(m.selectedAgency == msg.sender, "Not the assigned agency");

        
        emit DeliveryMarked(_missionId, msg.sender);
    }

    function approveDelivery(uint256 _missionId)
        external
        onlyRegistered
        onlyRole(Role.donor)
        missionMustExist(_missionId)
    {
        Mission storage m = missions[_missionId];

        require(m.donor == msg.sender, "Not the mission donor");
        require(m.status == MissionStatus.Transit, "Mission not Transit");

        uint256 escrowed = m.escrowBalance;

        
       uint256 feePercent;

        if (escrowed < 2 ether) {
            feePercent = 2;  
        } else {
            feePercent = 1;  
        }

        
        uint256 fee    = (escrowed * feePercent) / 100;
        uint256 payout = escrowed - fee;

        
        m.escrowBalance = 0;
        m.status        = MissionStatus.Delivered;

        
        users[m.selectedAgency].reputationScore += 15;

       
        (bool sent, ) = payable(m.selectedAgency).call{value: payout}("");
        require(sent, "Payout to agency failed");

        

        emit DeliveryApproved(_missionId, payout, fee);
    } //mansurun

    function raiseDispute(uint256 _missionId)
        external
        onlyRegistered
        onlyRole(Role.donor)
        missionMustExist(_missionId)
    {
        Mission storage m = missions[_missionId];

        require(m.donor == msg.sender, "Not the mission donor");
        require(m.status == MissionStatus.Transit, "Mission not Transit");

        m.status = MissionStatus.Disputed;

        emit MissionDisputed(_missionId, msg.sender);
    } 

    function resolveDispute(uint256 _missionId, bool _agencyFault)
        external
        onlyRegistered
        onlyRole(Role.arbiter)
        missionMustExist(_missionId)
    {
        Mission storage m = missions[_missionId];

        require(m.status == MissionStatus.Disputed, "Mission not Disputed");

        uint256 escrowed = m.escrowBalance;


        m.escrowBalance = 0;
        m.status        = MissionStatus.Resolved;

        if (_agencyFault) { // full refund to donor
          
            users[m.selectedAgency].reputationScore -= 30;

            (bool refunded, ) = payable(m.donor).call{value: escrowed}("");
            require(refunded, "Refund to donor failed");
        } else {
       
            uint256 feePercent = (escrowed < 2 ether) ? 2 : 1;
            uint256 fee        = (escrowed * feePercent) / 100;
            uint256 payout     = escrowed - fee;

            (bool sent, ) = payable(m.selectedAgency).call{value: payout}("");
            require(sent, "Payout to agency failed"); // fee remains in contract
        
        }

        emit DisputeResolved(_missionId, _agencyFault);
    }

    function getPledgeCount(uint256 _missionId)
        external
        view
        missionMustExist(_missionId)
        returns (uint256)
    {
        return missions[_missionId].pledges.length;
    }

    function getPledge(uint256 _missionId, uint256 _index)
        external
        view
        missionMustExist(_missionId)
        returns (address agency, uint256 bidAmount, bool isActive)
    {
        Pledge storage p = missions[_missionId].pledges[_index];
        return (p.agency, p.bidAmount, p.isActive);
    }

    function getMission(uint256 _missionId)
        external
        view
        missionMustExist(_missionId)
        returns (
            uint256 missionId,
            string memory category,
            uint256 maxBudget,
            string memory region,
            address donor,
            MissionStatus status,
            address selectedAgency,
            uint256 approvedBid,
            uint256 escrowBalance
        )
    {
        Mission storage m = missions[_missionId];
        return (
            m.missionId,
            m.category,
            m.maxBudget,
            m.region,
            m.donor,
            m.status,
            m.selectedAgency,
            m.approvedBid,
            m.escrowBalance
        );
    }

    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
} //wasi