// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract LinkedServe {
    address public officer;

    constructor() {
        officer = msg.sender;
    }

    enum Role { Guest, User, Applicant, NGO }

    enum Status { NotApplied, NotVerified, Approved, Rejected }

    struct User {
        string name;
        Role role;
    }

    struct Applicant {
        string note;
        Status status;
    }

    struct Opportunity {
        address ngo;
        string title;
        string description;
        uint applicantCount;
        bool closedOpportunity;
    }

    Opportunity[] public opportunities;
    uint public opportunityCount = 0;

    mapping(address => User) public users;

    mapping(uint => mapping(uint => address)) public applicantsAddress;
    mapping(uint => mapping(address => Applicant)) public applicants;

    uint NGOCount = 0;

    event UserRegistered(address indexed user, string name, Role role);

    event NGORegistered(address indexed ngo, address indexed officer);

    event OpportunityCreated(
        uint indexed opportunityId,
        address indexed ngo,
        string title,
        string description
    );

    event OpportunityClosed(uint indexed opportunityId, address indexed ngo);

    event ApplicationSubmitted(
        uint indexed opportunityId,
        address indexed applicant,
        string note
    );

    event ApplicationVerified(
        uint indexed opportunityId,
        address indexed applicant,
        Status status
    );

    modifier onlyOfficer() {
        require(msg.sender == officer, "Only the officer can call this function");
        _;
    }

    modifier onlyNGO() {
        require(users[msg.sender].role == Role.NGO, "Only NGOs can call this function");
        _;
    }

    modifier onlyUser() {
        require(users[msg.sender].role == Role.User, "Only Registered User can call this function");
        _;
    }

    function register(string memory _name) external {
        users[msg.sender] = User(_name, Role.User);
        emit UserRegistered(msg.sender, _name, Role.User);
    }

    function registerNGO(address _user) external onlyOfficer {
        users[_user].role = Role.NGO;
        NGOCount++;
        emit NGORegistered(_user, officer);
    }

    function createOpportunity(string memory _title, string memory _description) external onlyNGO returns (uint) {
        opportunities.push(Opportunity(msg.sender, _title, _description, 0, false));
        opportunityCount++;
        emit OpportunityCreated(opportunityCount, msg.sender, _title, _description);
        return opportunityCount;
    }

    function closeOpportunity(uint _opportunityid) external {
        require(opportunities[_opportunityid].ngo == msg.sender, "Only NGO Admin Can verify application");
        opportunities[_opportunityid].closedOpportunity = true;
        emit OpportunityClosed(_opportunityid, msg.sender);
    }

    function submitApplication(uint _opportunityId, string memory _note) external onlyUser {
        require(!opportunities[_opportunityId].closedOpportunity, "Opportunity has been closed by NGO");
        require(applicants[_opportunityId][msg.sender].status == Status.NotApplied, "You already applied in this opportunity");
        uint _id = opportunities[_opportunityId].applicantCount;
        opportunities[_opportunityId].applicantCount += 1;
        applicants[_opportunityId][msg.sender] = Applicant(_note, Status.NotVerified);
        applicantsAddress[_opportunityId][_id] = msg.sender;
        emit ApplicationSubmitted(_opportunityId, msg.sender, _note);
    }

    function verifyApplication(uint _opportunityid, address _applicant, Status _status) external {
        require(opportunities[_opportunityid].ngo == msg.sender, "Only NGO Admin Can verify application");
        applicants[_opportunityid][_applicant].status = _status;
        emit ApplicationVerified(_opportunityid, _applicant, _status);
    }
}
