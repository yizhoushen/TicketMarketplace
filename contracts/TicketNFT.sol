// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {ITicketNFT} from "./interfaces/ITicketNFT.sol";

// Uncomment this line to use console.log
import "hardhat/console.sol";

contract TicketNFT is ERC1155, ITicketNFT {
    // your code goes here (you can do it!)
    address contractOwner;

    constructor() ERC1155("") {
        contractOwner = msg.sender;
    }

    function mintFromMarketPlace(address to, uint256 nftId) external override {
        _mint(to, nftId, 1, "");
    }

    function getAddress() external view returns (address) {
        return address(this);
    }
    
    function owner() external view returns (address) {
        return contractOwner;
    }
}