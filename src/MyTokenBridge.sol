// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {OApp} from "@layerzerolabs/lz-oapp/contracts/OApp.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MyTokenBridge is OApp{
    IERC20 public immutable originalToken;
    uint32 public destinationEid;

    error NotEnoughNativeFee(uint _currentValue, uint _requiredValue);

    constructor(
        address _lzEndpoint,        
        address _originalToken,     
        address _initialOwner,     
        uint32 _destinationEid     
    ) OApp(_lzEndpoint, _initialOwner) {
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

        _lzSend(
            destinationEid, 
            payload,       
            options,       
            fee,            
            payable(msg.sender) 
        );
    }

    function _lzReceive(
        Origin calldata _origin,     // Struct with source chain ID and address
        bytes32 /*_guid*/,          // Globally unique message ID
        bytes calldata _payload,    // Your encoded message
        address /*_executor*/,      // Executor address
        bytes calldata /*_extraData*/ // Extra data
    ) internal override {
        // 1. The OApp contract automatically verifies the sender
        //    (i.e., that _origin.srcEid and _origin.sender match a trusted peer)
        //    if you have used setPeer() correctly.

        // 2. Decode the message (someone burned wrapped tokens to unlock)
        (uint amount, address to) = abi.decode(_payload, (uint, address));

        // 3. Unlock and send the original tokens back to the user
        originalToken.transfer(to, amount);
    }
}

