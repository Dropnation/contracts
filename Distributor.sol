// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;


import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "abdk-libraries-solidity/ABDKMath64x64.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

// Interface for the Staker contract
interface IStaker {
    function balances(address _staker) external view returns (uint256);
    function participants(uint256 _index) external view returns (address);
    function numberOfParticipants() external view returns (uint256);
}

contract Distributor is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using ABDKMath64x64 for uint256;

    uint256 public constant INIT_CLAIM = 70_750_200_000 * 1e18;
    uint256 public constant TOTAL_CLAIMABLE = 138_000_000_000_000 * 1e18;
    uint256 public constant STAKERS_CLAIM = 69_000_000_000_000 * 1e18;
    uint256 public claimedSupply;
    uint256 public farmersSupply;
    uint256 public farmerDrop;
    uint256 public activeFarmersLength;
    IERC20 public token;
    bytes32 public merkleRoot;
    address public harvester;

    event Claim(address indexed user, uint256 amount, address referrer);
    event Memedrop(address indexed staker, uint256 amount);


    mapping(address => bool) public claimedUser;
    mapping(address => bool) public claimedFarmer;
    mapping(address => bool) public ActiveFarmers; 
    mapping(address => uint256) public inviteRewards; 
    mapping(address => uint256) public inviteUsers;
    constructor(
        bytes32 root_, 
        IERC20 token_,
        address harvester_
    ) {
        merkleRoot = root_;
        token = token_;
        harvester = harvester_;
    }

    function setMerkleParam(bytes32 root_) external onlyOwner {
        merkleRoot = root_;
    }

    function claimable() public view returns(uint256) {
        uint256 supplyPerAddress = INIT_CLAIM;
        uint256 claimedPercent = percentClaimed();

        //decay 20% every 5% claim
        for(uint8 i; i < claimedPercent / 5e6; ++i) // decay = claimedPercent / 5e6
            supplyPerAddress = supplyPerAddress * 80 / 100;

        return supplyPerAddress;
    }

    function farmerSnapshot() external onlyOwner {
        IStaker staker = IStaker(harvester);
        uint256 numberOfParticipants = staker.numberOfParticipants();
        activeFarmersLength = numberOfParticipants;        
        for (uint256 i = 0; i < numberOfParticipants; i++) {
            address participant = staker.participants(i);
            uint256 balance = staker.balances(participant);
            uint256 threshold = 1_000_000 * 1e18;            
            if (balance > threshold) {
                ActiveFarmers[participant] = true;
            }
        }
        farmerDrop = STAKERS_CLAIM / activeFarmersLength;
    }

    function claimAirdrop (bytes32[] memory _proof, address referrer) public nonReentrant {        
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(claimedUser[msg.sender] == false, "Already claimed");
        require(claimedSupply < TOTAL_CLAIMABLE, "Memedrop has ended");
        require(MerkleProof.verify(_proof, merkleRoot, leaf), "Distributor: invalid proof");       
        claimedUser[msg.sender] = true;

        uint256 amount = claimable();
        require(amount >= 1e18, "Memedrop has ended");

        token.transfer(msg.sender, amount);

        claimedSupply += amount;

        if (referrer != address(0) && referrer != msg.sender) {
            uint256 num = amount * 100 / 1000;
            token.transfer(referrer, num);
            inviteRewards[referrer] += num;
            ++inviteUsers[referrer];
        }

        emit Claim(msg.sender, amount, referrer);
    }

    function claimMemedrop() public nonReentrant {
        require(ActiveFarmers[msg.sender], "Not a Farmer");
        require(!claimedFarmer[msg.sender], "Already claimed");
        require(farmerDrop + farmersSupply <= STAKERS_CLAIM, "Memedrop has ended");

        token.transfer(msg.sender, farmerDrop);
        farmersSupply += farmerDrop;
        claimedFarmer[msg.sender];

        emit Memedrop(msg.sender, farmerDrop);
    }

    function percentClaimed() public view returns(uint){
        return claimedSupply * 100e6 / TOTAL_CLAIMABLE; 
    }

    function setToken(IERC20 _token) external onlyOwner {
        token = _token;
    }

    function recoverToken(address[] calldata tokens) external onlyOwner {
        unchecked {
            for (uint8 i; i < tokens.length; ++i) {
                IERC20(tokens[i]).safeTransfer(msg.sender, IERC20(tokens[i]).balanceOf(address(this)));
            }
        }
    }    
}
