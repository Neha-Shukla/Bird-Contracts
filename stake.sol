pragma solidity ^0.8.0;

interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract StakeHere{
    using SafeMath for uint256;
    uint256 constant DAY = 1;          // 1 day
    uint256 constant POOL1ROI = 200;     // 0.02 %  change
    uint256 constant POOL2ROI = 5;     // 0.05 %
    uint256 constant POOL3ROI = 10;    // 1 %
    uint256 constant MONTH = 1;               // 1 month
    uint256 constant MAXPOOL1 = 360;          // 3.6 %
    uint256 constant MAXPOOL2 = 1800;         // 18 %
    uint256 constant MAXPOOL3 = 72000;        // 720 %
    
    uint256 public pool1Investments;
    uint256 public pool2Investments;
    uint256 public pool3Investments;
    
    address owner;
    
    IERC20 stakeToken = IERC20(0xd9145CCE52D386f254917e481eB44e9943F39138);
    
    struct User{
        uint256 investedAmount;
        uint256 withdrawnAmount;
        Deposit[] deposits;
        bool isExist;
        uint256 checkpoint;
    }
    
    struct Deposit{
        uint256 amount;
        uint256 start;
        uint256 withdrawn;
        bool principleWithdrawn;
    }
    
    mapping(address => User) public pool1Users;
    mapping(address => User) public pool2Users;
    mapping(address => User) public pool3Users;
    
    event depositedAmountSuccessFully(address _user,uint256 _amount, uint256 _pool);
    event withdrawnPoolAmountSuccessFully(uint256 _amount, uint256 _start, uint256 _now,uint256 _diff);
    event withdrawnPrincipleAmountSuccessFully(uint256 _amount, uint256 _start, uint256 _now,uint256 _diff);
    
    constructor() public{
        owner = msg.sender;
    }
    
    function investInPool(uint256 _pool,uint256 _amount) public payable{
        stakeToken.transferFrom(msg.sender,address(this),_amount);
        deposit(msg.sender,_pool,_amount);
    }
    
    function deposit(address _user,uint256 _pool,uint256 _amount) internal{
        if(_pool == 1){
            pool1Users[_user].investedAmount = pool1Users[_user].investedAmount.add(_amount);
            pool1Users[_user].deposits.push(Deposit(_amount,block.timestamp,0,false));
            pool1Investments = pool1Investments.add(_amount);
            if(pool1Users[_user].isExist == false){
                pool1Users[_user].isExist = true;
                pool1Users[_user].checkpoint = block.timestamp;
            }
        }
        // else if(_pool == 2){
        //     pool2Users[_user].investedAmount = pool2Users[_user].investedAmount.add(_amount);
        //     pool2Users[_user].deposits.push(Deposit(_amount,block.timestamp,0));
        //     pool2Investments = pool2Investments.add(_amount);
        // }
        // else if(_pool == 3){
        //     pool3Users[_user].investedAmount = pool3Users[_user].investedAmount.add(_amount);
        //     pool3Users[_user].deposits.push(Deposit(_amount,block.timestamp,0));
        //     pool3Investments = pool3Investments.add(_amount);
        // }
        emit depositedAmountSuccessFully(_user,_amount,_pool);
    }
    
    function withdrawPrincipleAmount(address _user,uint256 _pool) public{
        uint256 amount;
        uint256 totalAmount;
        for(uint256 i=0;i<pool1Users[_user].deposits.length;i++){
            if(pool1Users[_user].deposits[i].principleWithdrawn == false && block.timestamp.sub(pool1Users[_user].deposits[i].start) >= MONTH.mul(24)){
                amount = pool1Users[_user].deposits[i].amount;
                pool1Users[_user].deposits[i].principleWithdrawn = true;
            }
            totalAmount = totalAmount.add(amount);
        }
        stakeToken.transfer(_user,totalAmount);
        pool1Users[_user].withdrawnAmount = pool1Users[_user].withdrawnAmount.add(totalAmount);
    }
    
    function withdrawDailyYield(uint256 _pool) public{
        uint256 amount;
        uint256 totalAmount;
        for(uint256 i=0;i<pool1Users[msg.sender].deposits.length;i++){
            if(pool1Users[msg.sender].deposits[i].withdrawn<=(pool1Users[msg.sender].deposits[i].amount.mul(MAXPOOL1)).div(10000)){
                if(((pool1Users[msg.sender].deposits[i].withdrawn.add(pool1Users[msg.sender].deposits[i].amount).mul(POOL1ROI)).div(10000))<=pool1Users[msg.sender].deposits[i].amount.mul(MAXPOOL1).div(10000)){
                    if(pool1Users[msg.sender].deposits[i].start>pool1Users[msg.sender].checkpoint){
                        amount = pool1Users[msg.sender].deposits[i].amount.mul(POOL1ROI).mul(block.timestamp.sub(pool1Users[msg.sender].deposits[i].start)).div(DAY).div(10000);
                        emit withdrawnPoolAmountSuccessFully(amount,pool1Users[msg.sender].deposits[i].start,block.timestamp,block.timestamp.sub(pool1Users[msg.sender].deposits[i].start));  
                    }
                    else{
                        amount = pool1Users[msg.sender].deposits[i].amount.mul(POOL1ROI).mul(block.timestamp.sub(pool1Users[msg.sender].checkpoint)).div(DAY).div(10000);
                        emit withdrawnPoolAmountSuccessFully(amount,pool1Users[msg.sender].checkpoint,block.timestamp,block.timestamp.sub(pool1Users[msg.sender].checkpoint));  
                   
                    }
                }
                else{
                    amount = ((pool1Users[msg.sender].deposits[i].amount.mul(MAXPOOL1)).div(10000)).sub(pool1Users[msg.sender].deposits[i].withdrawn);
                    emit withdrawnPoolAmountSuccessFully(amount,pool1Users[msg.sender].checkpoint,block.timestamp,block.timestamp.sub(pool1Users[msg.sender].checkpoint));  
                   
                    
                }
                totalAmount = totalAmount.add(amount);
                pool1Users[msg.sender].deposits[i].withdrawn = pool1Users[msg.sender].deposits[i].withdrawn.add(amount);
            }
        }
        pool1Users[msg.sender].checkpoint = block.timestamp;
     
    }
    
    function getDailyYield(address _user,uint256 _pool) public view returns (uint256){
        uint256 amount;
        uint256 totalAmount;
        for(uint256 i=0;i<pool1Users[msg.sender].deposits.length;i++){
            if(pool1Users[msg.sender].deposits[i].withdrawn<=(pool1Users[msg.sender].deposits[i].amount.mul(MAXPOOL1)).div(10000)){
                if(((pool1Users[msg.sender].deposits[i].withdrawn.add(pool1Users[msg.sender].deposits[i].amount).mul(POOL1ROI)).div(10000))<=pool1Users[msg.sender].deposits[i].amount.mul(MAXPOOL1).div(10000)){
                    if(pool1Users[msg.sender].deposits[i].start>pool1Users[msg.sender].checkpoint){
                        amount = pool1Users[msg.sender].deposits[i].amount.mul(POOL1ROI).mul(block.timestamp.sub(pool1Users[msg.sender].deposits[i].start)).div(DAY).div(10000);
                        // emit withdrawnPoolAmountSuccessFully(amount,pool1Users[msg.sender].deposits[i].start,block.timestamp,block.timestamp.sub(pool1Users[msg.sender].deposits[i].start));  
                    }
                    else{
                        amount = pool1Users[msg.sender].deposits[i].amount.mul(POOL1ROI).mul(block.timestamp.sub(pool1Users[msg.sender].checkpoint)).div(DAY).div(10000);
                        // emit withdrawnPoolAmountSuccessFully(amount,pool1Users[msg.sender].checkpoint,block.timestamp,block.timestamp.sub(pool1Users[msg.sender].checkpoint));  
                   
                    }
                }
                else{
                    amount = ((pool1Users[msg.sender].deposits[i].amount.mul(MAXPOOL1)).div(10000)).sub(pool1Users[msg.sender].deposits[i].withdrawn);
                }
                totalAmount = totalAmount.add(amount);
            }
        }
        return totalAmount;        
    }
    
    function getContractBalance() public view returns(uint256){
        return stakeToken.balanceOf(address(this));
    }
    
    function getDepositInfo(address _user,uint256 _pool,uint256 _index) public view returns(uint256 _amount,uint256 _start, uint256 _withdrawn){
        if(_pool == 1){
           return (pool1Users[_user].deposits[_index].amount,pool1Users[_user].deposits[_index].start,pool1Users[_user].deposits[_index].withdrawn); 
        }
        else if(_pool == 2){
            return (pool2Users[_user].deposits[_index].amount,pool2Users[_user].deposits[_index].start,pool2Users[_user].deposits[_index].withdrawn); 
        }
        else if(_pool == 3){
            return (pool3Users[_user].deposits[_index].amount,pool3Users[_user].deposits[_index].start,pool3Users[_user].deposits[_index].withdrawn); 
        }
    }
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}
