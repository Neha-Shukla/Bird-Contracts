pragma solidity ^0.6.0;
import "AToken.sol";


contract C4K{
    using SafeMath for uint256;
    
    uint256 constant MONTH = 2;   //263520-->1 month secs
    uint256 constant ONE_TIME_REFERRER_INCOME_PERCENT=10;
    uint256 constant ONE_TIME_AMBASSADOR_INCOME_PERCENT=10;
    uint256 constant MIN_AMBASSADOR_AMOUNT = 50;   // 50k
    
    IERC20 public tokenA;
    
    address public admin;
    uint256 public adminAmount;
    
    uint256 public totalUsers;
    
    struct Deposit{
        uint256 amount;
        uint256 start;
        uint256 profitStart;
        uint256 profitEnd;
        uint256 principleStart;
        uint256 principleEnd;
        uint256 principleTimestamp;
        uint256 profitTimestamp;
    }
    
    struct User{
        uint256 id;
        Deposit[] deposits;
        uint256 totalReferrers;
        bool isAmbassador;
        bool isExist;
        address referrer;
        uint256 referrerIncomeToBeEarned;
        uint256 ambassadorIncomeToBeEarned;
        uint256 ambassadorIncomeEarned;
        uint256 referrerIncomeEarned;
        uint256 nextReferrerIncomeWithdrawnTime;
        uint256 nextAmbassadorIncomeWithdrawnTime;
        uint256 totalWithdrawn;
    }
    
    modifier onlyAdmin{
        require(msg.sender == admin);
        _;
    }
    
    // address public BToken;
    uint256 public totalInvestedTokens;
    mapping(address=>User) public users;
    
    event NewUserEntered(address _user,address _ref,uint256 _amount);
    event withdrawProfitEvent(address _user,uint256 _amount,uint256 _lastWithdraw,uint256 _curr,uint256 _diff);
    event withdrawPrincipleEvent(address _user,uint256 _amount,uint256 _lastWithdraw,uint256 _curr,uint256 _diff);
    
    constructor(IERC20 _addr) public{
        tokenA = _addr;
        admin = msg.sender;
    }
    
    function invest(address _ref,uint256 _amount) public{
        require(tokenA.allowance(msg.sender,address(this))>=_amount, "You must allow contract first to pay on your behalf");
        tokenA.transferFrom(msg.sender,address(this),_amount);
        
        if(_ref==address(0) || users[_ref].isExist==false || _ref == msg.sender){
            _ref=admin;
        }
        
        if(msg.sender == admin){
            _ref=address(0);
        }
        
        if(users[msg.sender].deposits.length==0){
            // new user
            users[msg.sender].referrer = _ref;
            users[msg.sender].isExist = true;
            users[_ref].totalReferrers = users[_ref].totalReferrers.add(1);
            totalUsers = totalUsers.add(1);
            users[msg.sender].id=totalUsers;
            users[msg.sender].nextAmbassadorIncomeWithdrawnTime = block.timestamp; 
            users[msg.sender].nextReferrerIncomeWithdrawnTime = block.timestamp;
        }
        _ref = users[msg.sender].referrer;
        
        users[msg.sender].deposits.push(Deposit(_amount,block.timestamp,
        block.timestamp.add(MONTH.mul(4)),block.timestamp.add(MONTH.mul(24)),
        block.timestamp.add(MONTH.mul(12)),block.timestamp.add(MONTH.mul(30)),
        block.timestamp,block.timestamp));
        
        adminAmount = adminAmount.add(_amount.mul(36).div(100));
        users[_ref].referrerIncomeToBeEarned = users[_ref].referrerIncomeToBeEarned.add(_amount.mul(16).div(100));
        if(checkIfAmbassador(_ref)){
            users[_ref].isAmbassador = true;
            users[_ref].ambassadorIncomeToBeEarned = users[_ref].ambassadorIncomeToBeEarned.add(_amount.mul(22).div(100));
        }
        totalInvestedTokens = totalInvestedTokens.add(_amount);
    }
    
    function getProfitAmount(address _user) public view returns (uint256){
        uint256 totalProfit;
        uint256 profit;
        for(uint256 i=0;i<users[_user].deposits.length;i++){
            if(users[_user].deposits[i].profitEnd<block.timestamp){
                profit = (users[_user].deposits[i].amount.mul(571).mul(block.timestamp.sub(users[_user].deposits[i].profitTimestamp))).div(10000).div(MONTH);
            totalProfit = totalProfit.add(profit);
            }
        }
        return totalProfit;
    }
    
    function getPrincipleAmount(address _user) public view returns (uint256){
        uint256 totalPrinciple;
        uint256 principle;
        for(uint256 i=0;i<users[_user].deposits.length;i++){
            if(users[_user].deposits[i].principleEnd<block.timestamp){
                principle = (users[_user].deposits[i].amount.mul(block.timestamp.sub(users[_user].deposits[i].principleTimestamp)).div(MONTH.mul(6)));
                totalPrinciple = totalPrinciple.add(principle);
            }
        }
        return totalPrinciple;
    }
    
    
   
    function checkIfAmbassador(address _user) public view returns(bool){
        if(users[_user].referrerIncomeEarned.add(users[_user].referrerIncomeToBeEarned)>=MIN_AMBASSADOR_AMOUNT){
            return true;
        }
        else
            return false;
    }
    
    function withdrawAmbassadorIncome(address _user) public{
        uint256 amount = users[_user].ambassadorIncomeToBeEarned.mul(ONE_TIME_AMBASSADOR_INCOME_PERCENT).div(100);
        require(amount>0, "must withdraw more than 0");
        require(users[_user].nextAmbassadorIncomeWithdrawnTime<=block.timestamp, "must withdraw after 1 month");
        
        users[_user].ambassadorIncomeEarned = users[_user].ambassadorIncomeEarned.add(amount);
        users[_user].ambassadorIncomeToBeEarned = users[_user].ambassadorIncomeToBeEarned.sub(amount);
        users[_user].nextAmbassadorIncomeWithdrawnTime = users[_user].nextAmbassadorIncomeWithdrawnTime.add(MONTH);
    }
    
    function withdrawReferrerIncome(address _user) public{
        uint256 amount = users[_user].referrerIncomeToBeEarned.mul(ONE_TIME_REFERRER_INCOME_PERCENT).div(100);
        require(amount>0, "must withdraw more than 0");
        require(users[_user].nextReferrerIncomeWithdrawnTime<=block.timestamp, "must withdraw after 1 month");
        
        users[_user].referrerIncomeEarned = users[_user].referrerIncomeEarned.add(amount);
        users[_user].referrerIncomeToBeEarned = users[_user].referrerIncomeToBeEarned.sub(amount);
        users[_user].nextReferrerIncomeWithdrawnTime = users[_user].nextReferrerIncomeWithdrawnTime.add(MONTH);
 
    }
    
    function withdrawProfit() public{
        uint256 totalProfit;
        uint256 profit;
        for(uint256 i=0;i<users[msg.sender].deposits.length;i++){
            if(users[msg.sender].deposits[i].profitEnd<block.timestamp){
                profit = (users[msg.sender].deposits[i].amount.mul(571).mul(block.timestamp.sub(users[msg.sender].deposits[i].profitTimestamp))).div(10000).div(MONTH);
                totalProfit = totalProfit.add(profit);
                if(profit>0){
                emit withdrawProfitEvent(msg.sender,profit,users[msg.sender].deposits[i].profitTimestamp,block.timestamp,block.timestamp.sub(users[msg.sender].deposits[i].profitTimestamp));
                users[msg.sender].deposits[i].profitTimestamp = users[msg.sender].deposits[i].profitTimestamp.add(block.timestamp);
                
                }
            }
        }
        
        tokenA.transferFrom(address(this),msg.sender,totalProfit);
        
    }
    
    function withdrawPrincipleAmount() public{
        uint256 totalPrinciple;
        uint256 principle;
        for(uint256 i=0;i<users[msg.sender].deposits.length;i++){
            if(users[msg.sender].deposits[i].principleEnd<block.timestamp){
                principle = (users[msg.sender].deposits[i].amount.mul(571).mul(block.timestamp.sub(users[msg.sender].deposits[i].principleTimestamp))).div(10000).div(MONTH.mul(6));
                totalPrinciple = totalPrinciple.add(principle);
                if(principle>0){
                emit withdrawPrincipleEvent(msg.sender,principle,users[msg.sender].deposits[i].principleTimestamp,block.timestamp,block.timestamp.sub(users[msg.sender].deposits[i].principleTimestamp));
                users[msg.sender].deposits[i].principleTimestamp = users[msg.sender].deposits[i].principleTimestamp.add(block.timestamp);
                
                }
            }
        }
        
        tokenA.transferFrom(address(this),msg.sender,totalPrinciple);
        
    }
    
    function withdrawAdminAmount() public onlyAdmin{
        tokenA.transfer(admin,adminAmount);
        adminAmount = 0;
    }
    
    function getDepositsInfo(address _user,uint256 _index) public view returns(uint256 amount,uint256 start,uint256 profitStart,uint256 profitEnd){
        return (users[_user].deposits[_index].amount,users[_user].deposits[_index].start,users[_user].deposits[_index].profitStart,users[_user].deposits[_index].profitEnd);
    }
    
}

