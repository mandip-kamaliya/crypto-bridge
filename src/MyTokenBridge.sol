// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// V2 Imports
import {OApp, Origin, MessagingFee} from "@layerzerolabs/oapp-evm/contracts/oapp/OApp.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract MyTokenBridge is OApp {
    IERC20 public immutable originalToken;
    uint32 public destinationEid; // Endpoint ID for Arc Testnet

    error NotEnoughNativeFee(uint256 _currentValue, uint256 _requiredValue);

    constructor(
        address _lzEndpoint, // Sepolia's V2 Endpoint address
        address _originalToken, // Your ERC20 token address on Sepolia
        address _initialOwner, // Your wallet address
        uint32 _destinationEid // Arc Testnet's Endpoint ID
    ) OApp(_lzEndpoint, _initialOwner) Ownable(_initialOwner) {
        originalToken = IERC20(_originalToken);
        destinationEid = _destinationEid;
    }

    function lockAndSend(uint64 _amount, address _to) public payable {
        originalToken.transferFrom(msg.sender, address(this), _amount);

        bytes memory payload = abi.encode(_amount, _to);
        bytes memory options = bytes("");

        MessagingFee memory fee = _quote(destinationEid, payload, options, false);
        if (msg.value < fee.nativeFee) {
            revert NotEnoughNativeFee(msg.value, fee.nativeFee);
        }

        _lzSend(destinationEid, payload, options, fee, payable(msg.sender));
    }

    function _lzReceive(
        Origin calldata _origin,
        bytes32, // _guid
        bytes calldata _payload,
        address, // _executor
        bytes calldata // _extraData
    ) internal override {
        // Automatically verifies peer with setPeer()
        (uint256 amount, address to) = abi.decode(_payload, (uint256, address));
        originalToken.transfer(to, amount);
    }
}
