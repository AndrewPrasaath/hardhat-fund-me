//SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;
//Imports
import "./PriceConverter.sol";
//import "hardhat/console.sol";
//Error Codes
error FundMe__NotOwner();

//Interfaces, Libraries, Contracts

/**@title A contract for crowd funding
 * @author Andrew Prasaath
 * @notice This contract is to demo a sample funding contract
 * @dev This implements price feeds as our library
 */
contract FundMe {
    //Type Declarations
    using PriceConverter for uint256;

    //State Variables
    address private immutable i_owner;
    uint256 public constant MIN_USD = 50 * 1e18;
    address[] private s_funders;
    mapping(address => uint256) private s_addressToAmtFunded;
    AggregatorV3Interface private s_priceFeed;

    //Modifier
    modifier onlyOwner() {
        //require(msg.sender == i_owner, "Sender is not owner");
        if (msg.sender != i_owner) {
            revert FundMe__NotOwner();
        }
        _;
    }

    //Functions Order:
    // ->constructor
    // ->receive
    // ->fallback
    // ->external
    // ->public
    // ->internal
    // ->private
    // ->view / pure

    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    //what if someone sends this contract without calling fund
    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }

    /**
     * @notice This function funds this contract
     * @dev This implements price feeds as our library
     */
    function fund() public payable {
        //minimum value
        require(
            msg.value.getConversionRate(s_priceFeed) >= MIN_USD,
            "Didn't send enough"
        ); //1e18 == 1 * 10 ** 18 == 1000000000000000000
        //console.log("%s funding %s ETH", msg.sender, msg.value);
        s_funders.push(msg.sender);
        s_addressToAmtFunded[msg.sender] += msg.value;
    }

    function withdraw() public onlyOwner {
        for (
            uint256 funderIndex;
            funderIndex < s_funders.length;
            funderIndex++
        ) {
            address funder = s_funders[funderIndex];
            s_addressToAmtFunded[funder] = 0; //values goes to 0 after withdraw
        }
        //resetting the array
        s_funders = new address[](0);

        // //actually withdraw fund - 3 ways to do
        // //1 transfer
        // payable(msg.sender).transfer(address(this).balance);
        // //2 send
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess, "Send failed");
        //3 call
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "Call failed");
    }

    function cheaperWithdraw() public onlyOwner {
        address[] memory funders = s_funders;
        //mapping can't be in memory, sorry!
        for (uint256 funderIndex; funderIndex < funders.length; funderIndex++) {
            address funder = funders[funderIndex];
            s_addressToAmtFunded[funder] = 0;
        }
        s_funders = new address[](0);

        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "Call failed");
    }

    //view/pure functions
    function getOwner() public view returns (address) {
        return i_owner;
    }

    function getFunder(uint256 funder) public view returns (address) {
        return s_funders[funder];
    }

    function getAddressToAmtFunded(address funder)
        public
        view
        returns (uint256)
    {
        return s_addressToAmtFunded[funder];
    }

    function getPriceFeed() public view returns (AggregatorV3Interface) {
        return s_priceFeed;
    }
}
