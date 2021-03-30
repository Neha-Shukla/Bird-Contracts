/**
 *Submitted for verification at BscScan.com on 2021-03-22
*/

// SPDX-License-Identifier: MIT

pragma solidity =0.7.0;

contract FomoStake {
    using SafeMath for uint256;

    uint256 public LAUNCH_TIME;
    uint256[] public REFERRAL_PERCENTS = [40, 20, 10, 5,5,5,5,5,5,5];
    uint256 public constant INVEST_MIN_AMOUNT = 0.05 ether;
    uint256 public constant PERCENT_STEP = 5;
    uint256 public constant PERCENTS_DIVIDER = 1000;
    uint256 public constant TIME_STEP = 1 days;
    uint256 public constant DECREASE_DAY_STEP = 0.5 days;
    uint256 public constant MARKETING_FEE = 50;
    uint256 public constant PROJECT_FEE = 50;

    uint256 public totalStaked;

    struct Plan {
        uint256 time;
        uint256 percent;
    }

    Plan[] internal plans;

    struct Deposit {
        uint8 plan;
        uint256 percent;
        uint256 amount;
        uint256 profit;
        uint256 start;
        uint256 finish;
        bool force;
    }

    struct User {
        Deposit[] deposits;
        uint256 checkpoint;
        address referrer;
        uint256[10] levels;
        uint256 bonus;
        uint256 totalBonus;
        uint256 holdBonus;
    }

    mapping(address => User) public users;
    mapping(address => Deposit[]) internal penaltyDeposits;

    address payable public marketingAddress;
    address payable public projectAddress;

    event Newbie(address user);
    
    event NewDeposit(
        address indexed user,
        uint8 plan,
        uint256 percent,
        uint256 amount,
        uint256 profit,
        uint256 start,
        uint256 finish
    );
    
    event Withdrawn(address indexed user, uint256 amount);
    

    event RefBonus(
        address indexed referrer,
        address indexed referral,
        uint256 indexed level,
        uint256 amount
    );
    
    event FeePayed(address indexed user, uint256 totalAmount);

    modifier beforeStarted() {
        require(block.timestamp >= LAUNCH_TIME, "!beforeStarted");
        _;
    }

    constructor(address payable marketingAddr, address payable projectAddr)
        public
    {
        require(!isContract(marketingAddr), "!marketingAddr");
        require(!isContract(projectAddr), "!projectAddr");

        marketingAddress = marketingAddr;
        projectAddress = projectAddr;

        if (getChainID() == 97) {
            LAUNCH_TIME = block.timestamp; // Test Network
        } else {
            LAUNCH_TIME = 1616590800;
        }

        plans.push(Plan(14, 80));
        plans.push(Plan(21, 65));
        plans.push(Plan(28, 50));
        plans.push(Plan(14, 80));
        plans.push(Plan(21, 65));
        plans.push(Plan(28, 50));
    }

    function invest(address referrer, uint8 plan)
        public
        payable
        beforeStarted()
    {
        require(msg.value >= INVEST_MIN_AMOUNT);
        require(plan < 6, "Invalid plan");

        marketingAddress.transfer(
            msg.value.mul(MARKETING_FEE).div(PERCENTS_DIVIDER)
        );
        projectAddress.transfer(
            msg.value.mul(PROJECT_FEE).div(PERCENTS_DIVIDER)
        );

        emit FeePayed(
            msg.sender,
            msg.value.mul(MARKETING_FEE.add(PROJECT_FEE)).div(PERCENTS_DIVIDER)
        );

        User storage user = users[msg.sender];

        if (user.referrer == address(0)) {
            if (referrer != msg.sender) {
                user.referrer = referrer;
            }

            address upline = user.referrer;
            for (uint256 i = 0; i < 10; i++) {
                if (upline != address(0)) {
                    users[upline].levels[i] = users[upline].levels[i].add(1);
                    upline = users[upline].referrer;
                } else break;
            }
        }

        if (user.referrer != address(0)) {
            address upline = user.referrer;
            for (uint256 i = 0; i < 10; i++) {
                if (upline != address(0)) {
                    uint256 amount =
                        msg.value.mul(REFERRAL_PERCENTS[i]).div(
                            PERCENTS_DIVIDER
                        );
                    users[upline].bonus = users[upline].bonus.add(amount);
                    payable(upline).transfer(amount);
                    users[upline].totalBonus = users[upline].totalBonus.add(
                        amount
                    );
                    
                    emit RefBonus(upline, msg.sender, i, amount);
                    upline = users[upline].referrer;
                } else break;
            }
        }

        if (user.deposits.length == 0) {
            user.checkpoint = block.timestamp;
            emit Newbie(msg.sender);
        }

        (uint256 percent, uint256 profit, , uint256 finish) =
            getResult(plan, msg.value);
        user.deposits.push(
            Deposit(
                plan,
                percent,
                msg.value,
                profit,
                block.timestamp,
                finish,
                true
            )
        );

        totalStaked = totalStaked.add(msg.value);
        emit NewDeposit(
            msg.sender,
            plan,
            percent,
            msg.value,
            profit,
            block.timestamp,
            finish
        );
    }

    function withdraw() public beforeStarted() {
        User storage user = users[msg.sender];

        uint256 totalAmount = getUserDividends(msg.sender);


        require(totalAmount > 0, "User has no dividends");

        uint256 contractBalance = address(this).balance;
        if (contractBalance < totalAmount) {
            totalAmount = contractBalance;
        }

        user.checkpoint = block.timestamp;

        for (uint256 i = 0; i < user.deposits.length; i++) {
            if (user.checkpoint < user.deposits[i].finish) {
                if (user.deposits[i].plan < 3) {
                    user.deposits[i].force = false;
                } else if (block.timestamp > user.deposits[i].finish) {
                    user.deposits[i].force = false;
                }
            }
        }
        
        msg.sender.transfer(totalAmount.sub(totalAmount.mul(3).div(10)));
        users[msg.sender].holdBonus = users[msg.sender].holdBonus.add(totalAmount.mul(3).div(10));

        emit Withdrawn(msg.sender, totalAmount);
    }

    function reInvest(uint8 plan) public {
        require(plan < 6, "Invalid plan");
    uint256 amount = users[msg.sender].holdBonus;
        marketingAddress.transfer(
            amount.mul(MARKETING_FEE).div(PERCENTS_DIVIDER)
        );
        projectAddress.transfer(
            amount.mul(PROJECT_FEE).div(PERCENTS_DIVIDER)
        );

        emit FeePayed(
            msg.sender,
            amount.mul(MARKETING_FEE.add(PROJECT_FEE)).div(PERCENTS_DIVIDER)
        );

        User storage user = users[msg.sender];

   
            address upline = user.referrer;
            for (uint256 i = 0; i < 10; i++) {
                if (upline != address(0)) {
                    users[upline].levels[i] = users[upline].levels[i].add(1);
                    upline = users[upline].referrer;
                } else break;
            }
     
            upline = user.referrer;
            for (uint256 i = 0; i < 10; i++) {
                if (upline != address(0)) {
                    uint256 _amount =
                        amount.mul(REFERRAL_PERCENTS[i]).div(
                            PERCENTS_DIVIDER
                        );
                    users[upline].bonus = users[upline].bonus.add(_amount);
                    users[upline].totalBonus = users[upline].totalBonus.add(
                        _amount
                    );
                    payable(upline).transfer(_amount);
                    emit RefBonus(upline, msg.sender, i, _amount);
                    upline = users[upline].referrer;
                } else break;
            }
       

        (uint256 percent, uint256 profit, , uint256 finish) =
            getResult(plan, amount);
        user.deposits.push(
            Deposit(
                plan,
                percent,
                amount,
                profit,
                block.timestamp,
                finish,
                true
            )
        );

        totalStaked = totalStaked.add(amount);
        
        emit NewDeposit(
            msg.sender,
            plan,
            percent,
            amount,
            profit,
            block.timestamp,
            finish
        );
        user.holdBonus = 0;
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getPlanInfo(uint8 plan)
        public
        view
        returns (uint256 time, uint256 percent)
    {
        time = plans[plan].time;
        percent = plans[plan].percent;
    }

    function getPercent(uint8 plan) public view returns (uint256) {
        if (block.timestamp > LAUNCH_TIME) {
            return
                plans[plan].percent.add(
                    PERCENT_STEP.mul(block.timestamp.sub(LAUNCH_TIME)).div(
                        TIME_STEP
                    )
                );
        } 
        
        else {
            return plans[plan].percent;
        }
    }

    function getResult(uint8 plan, uint256 deposit)
        public
        view
        returns (
            uint256 percent,
            uint256 profit,
            uint256 current,
            uint256 finish
        )
    {
        percent = getPercent(plan);

        if (plan < 3) {
            profit = deposit.mul(percent).div(PERCENTS_DIVIDER).mul(
                plans[plan].time
            );
        } else if (plan < 6) {
            for (uint256 i = 0; i < plans[plan].time; i++) {
                profit = profit.add(
                    (deposit.add(profit)).mul(percent).div(PERCENTS_DIVIDER)
                );
            }
        }

        current = block.timestamp;
        finish = current.add(getDecreaseDays(plans[plan].time));
    }

    function getUserDividends(address userAddress)
        public
        view
        returns (uint256)
    {
        User memory user = users[userAddress];

        uint256 totalAmount;

        for (uint256 i = 0; i < user.deposits.length; i++) {
            if (user.checkpoint < user.deposits[i].finish) {
                if (user.deposits[i].plan < 3) {
                    uint256 share =
                        user.deposits[i]
                            .amount
                            .mul(user.deposits[i].percent)
                            .div(PERCENTS_DIVIDER);
                    uint256 from =
                        user.deposits[i].start > user.checkpoint
                            ? user.deposits[i].start
                            : user.checkpoint;
                    uint256 to =
                        user.deposits[i].finish < block.timestamp
                            ? user.deposits[i].finish
                            : block.timestamp;
                    if (from < to) {
                        uint256 planTime =
                            plans[user.deposits[i].plan].time.mul(TIME_STEP);
                        uint256 redress =
                            planTime.div(
                                getDecreaseDays(
                                    plans[user.deposits[i].plan].time
                                )
                            );

                        totalAmount = totalAmount.add(
                            share.mul(to.sub(from)).mul(redress).div(TIME_STEP)
                        );
                    }
                } else if (block.timestamp > user.deposits[i].finish) {
                    totalAmount = totalAmount.add(user.deposits[i].profit);
                }
            }
        }

        return totalAmount;
    }

    function getDecreaseDays(uint256 planTime) public view returns (uint256) {
        uint256 limitDays = uint256(5).mul(TIME_STEP);
        uint256 pastDays = block.timestamp.sub(LAUNCH_TIME).div(TIME_STEP);
        uint256 decreaseDays = pastDays.mul(DECREASE_DAY_STEP);
        uint256 minimumDays = planTime.mul(TIME_STEP).sub(decreaseDays);

        if (planTime.mul(TIME_STEP).sub(decreaseDays) < limitDays) {
            return limitDays;
        }

        return minimumDays;
    }

    function getUserCheckpoint(address userAddress)
        public
        view
        returns (uint256)
    {
        return users[userAddress].checkpoint;
    }

    function getUserReferrer(address userAddress)
        public
        view
        returns (address)
    {
        return users[userAddress].referrer;
    }

    function getUserDownlineCount(address userAddress,uint256 level)
        public
        view
        returns (
            uint256
        )
    {
       if(level==1){
           return users[userAddress].levels[0];
       }
       if(level==2){
           return users[userAddress].levels[1];
       }
       if(level==3){
           return users[userAddress].levels[2];
       }
       if(level==4){
           return users[userAddress].levels[3];
       }
       if(level==5){
           return users[userAddress].levels[4];
       }
       if(level==6){
           return users[userAddress].levels[5];
       }
       if(level==7){
           return users[userAddress].levels[6];
       }
       if(level==8){
           return users[userAddress].levels[7];
       }
       if(level==9){
           return users[userAddress].levels[8];
       }
       if(level==10){
           return users[userAddress].levels[9];
       }
    }


    function getUserReferralTotalBonus(address userAddress)
        public
        view
        returns (uint256)
    {
        return users[userAddress].totalBonus;
    }



    function getUserAvailable(address userAddress)
        public
        view
        returns (uint256)
    {
        return
                getUserDividends(userAddress);
            
    }

    function getUserAmountOfDeposits(address userAddress)
        public
        view
        returns (uint256)
    {
        return users[userAddress].deposits.length;
    }

    function getUserAmountOfPenaltyDeposits(address userAddress)
        public
        view
        returns (uint256)
    {
        return penaltyDeposits[userAddress].length;
    }

    function getUserTotalDeposits(address userAddress)
        public
        view
        returns (uint256 amount)
    {
        for (uint256 i = 0; i < users[userAddress].deposits.length; i++) {
            amount = amount.add(users[userAddress].deposits[i].amount);
        }
    }

    function getUserDepositInfo(address userAddress, uint256 index)
        public
        view
        returns (
            uint8 plan,
            uint256 percent,
            uint256 amount,
            uint256 profit,
            uint256 start,
            uint256 finish,
            bool force
        )
    {
        User memory user = users[userAddress];

        require(index < user.deposits.length, "Invalid index");

        plan = user.deposits[index].plan;
        percent = user.deposits[index].percent;
        amount = user.deposits[index].amount;
        profit = user.deposits[index].profit;
        start = user.deposits[index].start;
        finish = user.deposits[index].finish;
        force = user.deposits[index].force;
    }

   
    function getChainID() public pure returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    function isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }
}
