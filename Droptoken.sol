// SPDX-License-Identifier: MIT

// @title Drop token for Dropnation
// https://twitter.com/0xSorcerers | https://github.com/Dark-Viper | https://t.me/Oxsorcerer | https://t.me/battousainakamoto | https://t.me/darcViper

pragma solidity ^0.8.17;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "abdk-libraries-solidity/ABDKMath64x64.sol";
import "./ERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Dropnation is ERC20, Ownable, ReentrancyGuard {        
        constructor(string memory _name, string memory _symbol, address _newGuard, 
        address _droperWallet, address _devWallet, address _lpWallet, address _farmerWallet, address _deadWallet) 
            ERC20(_name, _symbol)
        {
        guard = _newGuard;        
        droperWallet = _droperWallet;
        devWallet = _devWallet;
        lpWallet = _lpWallet;
        farmerWallet = _farmerWallet;
        deadWallet = _deadWallet;

        }
    using ABDKMath64x64 for uint256;
    using SafeMath for uint256;

    address public burnercontract;
    
    bool public paused = false;
    address private guard;
    uint256 public MAX_SUPPLY = 690000000000000 * 10 ** decimals();
    uint256 public TotalBurns;

    modifier onlyGuard() {
        require(msg.sender == guard, "Not authorized.");
        _;
    }

    modifier onlyBurner() {
        require(msg.sender == burnercontract, "Not authorized.");
        _;
    }

    event mintEvent(uint256 indexed multiplier);
    function mint(uint256 _multiplier) external onlyOwner {        
        require(!paused, "Paused Contract");
        require(_multiplier > 0, "Invalid Multiplier");
        require(totalSupply() < MAX_SUPPLY, "Max Minted");
        uint256 multiplier =  _multiplier * (1_000_000 * 10 ** decimals());
        require(totalSupply() + multiplier <= MAX_SUPPLY, "Max Exceeded");
        _mint(msg.sender, multiplier);  
        emit mintEvent(multiplier);
    }

    event burnEvent(uint256 indexed _amount);
    function Burn(uint256 _amount) external onlyBurner {                
       require(!paused, "Paused Contract");
       _burn(msg.sender, _amount);
       TotalBurns += _amount;
       emit burnEvent(_amount);
    }

    function Burner(uint256 _amount) external onlyOwner {                
        require(!paused, "Paused Contract");
       _burn(msg.sender, _amount);
       TotalBurns += _amount;
       emit burnEvent(_amount);
    }

    event Pause();
    function pause() public onlyGuard {
        require(!paused, "Contract already paused.");
        paused = true;
        emit Pause();
    }

    event Unpause();
    function unpause() public onlyGuard {
        require(msg.sender == owner(), "Only Deployer.");
        require(paused, "Contract not paused.");
        paused = false;
        emit Unpause();
    }

    /**
     * @dev sets wallets tax is sent to.
     */
    function setWallets (address _droperwallet, address _lpwallet, address _devWallet, address _farmerWallet) external onlyOwner {
        droperWallet = _droperwallet;
        lpWallet = _lpwallet;
        devWallet = _devWallet;
        farmerWallet = _farmerWallet;
    }

    function setBurner (address _burner) external onlyOwner {
        burnercontract = _burner;
    }

    function setGuard (address _newGuard) external onlyGuard {
        guard = _newGuard;
    }
}
