// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract DonateRefugee {
    event NewRefuge(
        string nameSurname,
        bool married,
        bool male,
        uint8 childCount,
        string location,
        string nationality,
        uint256 balance,
        uint256 neededBalance,
        string needReason,
        address payable refugeeAddress
    );

    event Donate(
        address payable refugeeAddress,
        address donorAddress,
        uint256 amount,
        // int256 remainingAmount,
        uint256 timestamp
    );

    struct Refugee {
        uint256 id;
        string nameSurname;
        bool married;
        bool male;
        uint8 childCount;
        string location;
        string nationality;
        uint256 balance;
        uint256 neededBalance;
        string needReason;
        address payable refugeeAddress;
    }

    Refugee[] public refugees;
    uint256 refugeeId = 0;
    uint256 createDate = 0;
    mapping(address => Refugee) public refugeeList;

    modifier isSameUser(address payable rAddress, address sender) {
        require(
            rAddress != sender,
            "You can not create multiple accounts or Donate to yourself"
        );
        _;
    }

    modifier isReachedLimit(uint256 neededBalance, uint256 balance) {
        require(
            neededBalance > balance,
            "The refugee already reached the goal. Help to other refugees by donating!"
        );
        _;
    }

    function registerAsRefugee(
        string memory _nameSurname,
        bool _married,
        bool _male,
        uint8 _childCount,
        string memory _location,
        string memory _nationality,
        uint256 _neededBalance,
        string memory _needReason
    )
        public
        isSameUser(
            refugeeList[address(msg.sender)].refugeeAddress,
            address(msg.sender)
        )
    {
        refugeeList[address(msg.sender)] = Refugee(
            refugeeId,
            _nameSurname,
            _married,
            _male,
            _childCount,
            _location,
            _nationality,
            msg.sender.balance,
            _neededBalance * (10 ** 18),
            _needReason,
            payable(address(msg.sender))
        );

        refugees.push(
            Refugee(
                refugeeId,
                _nameSurname,
                _married,
                _male,
                _childCount,
                _location,
                _nationality,
                msg.sender.balance,
                _neededBalance * (10 ** 18),
                _needReason,
                payable(address(msg.sender))
            )
        );

        emit NewRefuge(
            _nameSurname,
            _married,
            _male,
            _childCount,
            _location,
            _nationality,
            msg.sender.balance,
            _neededBalance,
            _needReason,
            payable(address(msg.sender))
        );

        refugeeId++;
    }

    // Public copies the data from memory but external reads from memory.
    // I did this for gas optimization.
    function returnRefugees() external view returns (Refugee[] memory) {
        return refugees;
    }

    function donateToRefugee(
        address payable _refugeeAddress
    )
        public
        payable
        isReachedLimit(
            refugeeList[_refugeeAddress].neededBalance,
            refugeeList[_refugeeAddress].balance
        )
        isSameUser(
            refugeeList[_refugeeAddress].refugeeAddress,
            address(msg.sender)
        )
    {
        _refugeeAddress.transfer(msg.value);

        refugeeList[_refugeeAddress].balance += uint256(msg.value);
        refugees[refugeeList[_refugeeAddress].id].balance += uint256(msg.value);

        emit Donate(
            payable(address(_refugeeAddress)),
            address(msg.sender),
            msg.value,
            block.timestamp
        );
    }
}
