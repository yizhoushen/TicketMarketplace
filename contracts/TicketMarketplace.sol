// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {ITicketNFT} from "./interfaces/ITicketNFT.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {TicketNFT} from "./TicketNFT.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol"; 
import {ITicketMarketplace} from "./interfaces/ITicketMarketplace.sol";
import "hardhat/console.sol";

contract TicketMarketplace is ITicketMarketplace {
    // your code goes here (you can do it!)
    using Math for uint256;
    address public admin;
    TicketNFT public nftContract;
    address public ERC20Token;

    struct Event {
        uint128 nextTicketToSell;
        uint128 maxTickets;
        uint256 pricePerTicket;
        uint256 pricePerTicketERC20;
    }

    mapping(uint128 => Event) public events;
    uint128 public currentEventId = 0;

    constructor(address _coinAddress) {
        admin = msg.sender;
        nftContract = new TicketNFT();
        ERC20Token = _coinAddress;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Unauthorized access");
        _;
    }

    function createEvent(uint128 maxTickets, uint256 pricePerTicket, uint256 pricePerTicketERC20) external override onlyAdmin {
        events[currentEventId] = Event(0, maxTickets, pricePerTicket, pricePerTicketERC20);
        emit EventCreated(currentEventId, maxTickets, pricePerTicket, pricePerTicketERC20);
        currentEventId++;
    }

    function setMaxTicketsForEvent(uint128 eventId, uint128 newMaxTickets) external override onlyAdmin {
        Event storage eventInfo = events[eventId];
        require(newMaxTickets >= eventInfo.maxTickets, "The new number of max tickets is too small!");
        eventInfo.maxTickets = newMaxTickets;
        emit MaxTicketsUpdate(eventId, newMaxTickets);
    }

    function setPriceForTicketETH(uint128 eventId, uint256 price) external override onlyAdmin {
        events[eventId].pricePerTicket = price;
        emit PriceUpdate(eventId, price, "ETH");
    }

    function setPriceForTicketERC20(uint128 eventId, uint256 price) external override onlyAdmin {
        events[eventId].pricePerTicketERC20 = price;
        emit PriceUpdate(eventId, price, "ERC20");
    }

    function buyTickets(uint128 eventId, uint128 ticketCount) payable external override {
        require(eventId < currentEventId, "No such event!");
        Event storage eventInfo = events[eventId];
        (bool success, uint256 totalPrice) = Math.tryMul(eventInfo.pricePerTicket, ticketCount);
        require(success, "Overflow happened while calculating the total price of tickets. Try buying smaller number of tickets.");
        require(ticketCount <= eventInfo.maxTickets, "We don't have that many tickets left to sell!");
        require(msg.value >= totalPrice, "Not enough funds supplied to buy the specified number of tickets.");
        
        // if (msg.value > totalPrice) {
        //     uint256 refund = msg.value - totalPrice;
        //     payable(msg.sender).transfer(refund);
        // }

        for(uint256 i = 0; i < ticketCount; i++){
            uint256 ticketNFTId = (uint256(eventId) << 128) + eventInfo.nextTicketToSell;
            // console.log("newTicketNFtId", ticketNFTId);
            nftContract.mintFromMarketPlace(msg.sender, ticketNFTId);
            eventInfo.nextTicketToSell++;
        }
        emit TicketsBought(eventId, ticketCount, "ETH");
    }

    function buyTicketsERC20(uint128 eventId, uint128 ticketCount) external override {
        require(eventId < currentEventId, "No such event!");
        Event storage eventInfo = events[eventId];
        (bool success, uint256 totalPrice) = Math.tryMul(eventInfo.pricePerTicketERC20, ticketCount);
        require(success, "Overflow happened while calculating the total price of tickets. Try buying smaller number of tickets.");
        require(ticketCount <= eventInfo.maxTickets, "We don't have that many tickets left to sell!");
        require(IERC20(ERC20Token).balanceOf(msg.sender) >= totalPrice, "Not enough funds supplied to buy the specified number of tickets.");
        IERC20(ERC20Token).transferFrom(msg.sender, address(this), totalPrice);

        for(uint128 i = 0; i < ticketCount; i++){
            uint256 ticketNFTId = (uint256(eventId) << 128) + eventInfo.nextTicketToSell;
            nftContract.mintFromMarketPlace(msg.sender, ticketNFTId);
            eventInfo.nextTicketToSell++;
        }
        emit TicketsBought(eventId, ticketCount, "ERC20");
    }

    function setERC20Address(address newERC20Address) external override onlyAdmin {
        ERC20Token = newERC20Address;
        emit ERC20AddressUpdate(newERC20Address);
    }

    function ERC20Address() external view returns (address) {
        return ERC20Token;
    }

    function getAddress() external view returns (address) {
        return address(this);
    }

    function owner() external view returns (address) {
        return admin;
    }
    
}