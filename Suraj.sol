pragma solidity ^0.6.0;

contract SS{
    using SafeMath for uint256;
    uint256 constant public MIN_AMOUNT = 110000000;   //110 TRX
    uint256 constant public DAILY_ROI = 2;   //2%
    uint256 constant TRX = 1000000;
    uint256 constant TIME = 1;
    
    address owner;
    uint256 totalUsers;
    uint256 public markettingWallet;
    uint256[] LevelIncome;
    uint256[] PoolPrice;
    
    uint public pool1currUserID = 0;
    uint public pool2currUserID = 0;
    uint public pool3currUserID = 0;
    uint public pool4currUserID = 0;
    uint public pool5currUserID = 0;
    uint public pool6currUserID = 0;
    uint public pool7currUserID = 0;
    uint public pool8currUserID = 0;
    uint public pool9currUserID = 0;
    
    struct User{
        address referrer;
        uint256 levelIncome;
        uint256 invested;
        uint256 hold;
        uint256 withdrawn;
        uint256 startTime;
        bool isExist;
        uint256 poolWallet;
        uint256 withdrawWallet;
        uint256 ROIAmount;
        uint256 ROITime;
        uint256 poolAmoutWithdrawn;
        uint256 count;
        uint256 prevInvest;
    }
    struct PoolUserStruct {
        bool isExist;
        uint id;
        address down1;
        address down2;
    }
    struct Income{
        uint256 rewardEarned;
        uint256 levelIncomeEarned;
    }
    
    mapping (address => PoolUserStruct) public pool1users;
     mapping (uint => address) public pool1userList;
     
     mapping (address => PoolUserStruct) public pool2users;
     mapping (uint => address) public pool2userList;
     
     mapping (address => PoolUserStruct) public pool3users;
     mapping (uint => address) public pool3userList;
     
     mapping (address => PoolUserStruct) public pool4users;
     mapping (uint => address) public pool4userList;
     
     mapping (address => PoolUserStruct) public pool5users;
     mapping (uint => address) public pool5userList;
     
     mapping (address => PoolUserStruct) public pool6users;
     mapping (uint => address) public pool6userList;
     
     mapping (address => PoolUserStruct) public pool7users;
     mapping (uint => address) public pool7userList;
     
     mapping (address => PoolUserStruct) public pool8users;
     mapping (uint => address) public pool8userList;
     
     mapping (address => PoolUserStruct) public pool9users;
     mapping (uint => address) public pool9userList;
     
    mapping(address=>User) public users;
    mapping(address=>Income) public incomes;
    event investedSuccessfullyEvent(address _user,address _ref,uint256 _amount);
   
    constructor() public{
        owner = msg.sender;
        LevelIncome.push(500);
        LevelIncome.push(300);
        LevelIncome.push(200);
        LevelIncome.push(100);
        LevelIncome.push(50);
        LevelIncome.push(30);
        LevelIncome.push(20);
        LevelIncome.push(10);
        LevelIncome.push(1);
        LevelIncome.push(1);
        LevelIncome.push(1);
        LevelIncome.push(1);
        LevelIncome.push(1);
        LevelIncome.push(1);
        LevelIncome.push(1);
        
        //add pool
        PoolPrice.push(TRX.mul(100));
        
        //change to 500
        PoolPrice.push(TRX.mul(200));
        PoolPrice.push(TRX.mul(1500));
        PoolPrice.push(TRX.mul(2000));
        PoolPrice.push(TRX.mul(2500));
        PoolPrice.push(TRX.mul(5000));
        PoolPrice.push(TRX.mul(10000));
        PoolPrice.push(TRX.mul(20000));
        PoolPrice.push(TRX.mul(25000));
        
    }
    
    function invest(address _ref) external payable{
        require(users[msg.sender].isExist == false, "user already have active investment");
        require(msg.value>=MIN_AMOUNT, "must pay minimum amount");
        require((msg.value.sub(TRX.mul(10)))%10==0, "you must pay in multiple of 10");
        require(users[msg.sender].hold == 0, "user is active");
        
        // 10 trx to admin
        address(uint256(owner)).transfer(TRX.mul(10));
        
        _invest(msg.sender,_ref,msg.value.sub(TRX.mul(10)));    
    }
    
    function _invest(address _user,address _ref,uint256 _amount) internal {
        
        
        if(!users[_ref].isExist){
            _ref = owner;
        }
        
        if(_user == owner){
            _ref = address(0);
        }
        
        if(users[_user].referrer != address(0)){
            _ref = users[_user].referrer;
        }
        totalUsers = totalUsers.add(1);
       
        users[_user].referrer = _ref;
        if(_amount>=TRX.mul(2500)){
            users[_ref].count = users[_ref].count.add(1);
            if(users[_ref].count >= 10){
                incomes[_ref].rewardEarned = incomes[_ref].rewardEarned.add(_amount.mul(5).div(100)); 
                address(uint256(_ref)).transfer(_amount.mul(5).div(100));
            }
        }
        users[_user].invested = _amount;
        users[_user].startTime = block.timestamp;
        users[_user].isExist = true;
        users[_user].ROITime = block.timestamp;
       
        //giveLevelIncome
        giveLevelIncome(_ref,_amount);
        
    
        
        emit investedSuccessfullyEvent(_user,_ref,_amount);
    }
    
    function giveLevelIncome(address _ref,uint256 _amount) internal{
    
        for(uint256 i=0;i<15;i++){
            if(_ref==address(0)){
                break;
            }
            users[_ref].levelIncome = users[_ref].levelIncome .add(LevelIncome[i].mul(_amount).div(10000));
             _ref = users[_ref].referrer;
        }
       
    }
    
    function buyPackage(uint256 _poolNumber) public{
        // set pool PoolPrice
        giveROI(msg.sender);
        
         // check if pool price is enough
        require(users[msg.sender].poolWallet>=PoolPrice[_poolNumber-1],"amount must be greater or equal to pool price");
      
        // deduct pool wallet amount
         users[msg.sender].poolWallet = users[msg.sender].poolWallet.sub(PoolPrice[_poolNumber-1]);
        
        // add user to given Pool
        // check if any user's tree completes
            // if yes then give them amount and remove them from Pool
            // if not then do nothing
        if(_poolNumber==1){
            require(!pool1users[msg.sender].isExist, "you have purchased the pool before");
            pool1currUserID = pool1currUserID+1;
            pool1users[msg.sender] = PoolUserStruct(true,pool1currUserID,address(0),address(0));
            pool1userList[pool1currUserID]=msg.sender;
            if(pool1currUserID>=2){
                if(pool1users[pool1userList[pool1currUserID/2]].down1 == address(0)){
                    pool1users[pool1userList[pool1currUserID/2]].down1 = msg.sender;
                }
                
                else if(pool1users[pool1userList[pool1currUserID/2]].down2 == address(0)){
                    pool1users[pool1userList[pool1currUserID/2]].down2 = msg.sender;
                    dividePoolAmount(pool1userList[pool1currUserID/2],_poolNumber);
                    pool1users[pool1userList[pool1currUserID/2]].isExist = false;
                }
            }
        }
        if(_poolNumber==2){
            require(!pool2users[msg.sender].isExist, "you have purchased the pool before");
            pool2currUserID = pool2currUserID+1;
            pool2users[msg.sender] = PoolUserStruct(true,pool2currUserID,address(0),address(0));
            pool2userList[pool2currUserID]=msg.sender;
            if(pool2currUserID>=2){
                if(pool2users[pool2userList[pool2currUserID/2]].down1 == address(0)){
                    pool2users[pool2userList[pool2currUserID/2]].down1 = msg.sender;
                }
                
                else if(pool2users[pool2userList[pool2currUserID/2]].down2 == address(0)){
                    pool2users[pool2userList[pool2currUserID/2]].down2 = msg.sender;
                    dividePoolAmount(pool2userList[pool2currUserID/2],_poolNumber);
                    pool2users[pool2userList[pool2currUserID/2]].isExist = false;
                }
            }
        }
        if(_poolNumber==3){
            require(!pool3users[msg.sender].isExist, "you have purchased the pool before");
            pool3currUserID = pool3currUserID+1;
            pool3users[msg.sender] = PoolUserStruct(true,pool3currUserID,address(0),address(0));
            pool3userList[pool3currUserID]=msg.sender;
            if(pool3currUserID>=2){
                if(pool3users[pool3userList[pool3currUserID/2]].down1 == address(0)){
                    pool3users[pool3userList[pool3currUserID/2]].down1 = msg.sender;
                }
                
                else if(pool3users[pool3userList[pool3currUserID/2]].down2 == address(0)){
                    pool3users[pool3userList[pool3currUserID/2]].down2 = msg.sender;
                    dividePoolAmount(pool3userList[pool3currUserID/2],_poolNumber);
                    pool3users[pool3userList[pool3currUserID/2]].isExist = false;
                }
            }
        }
        if(_poolNumber==4){
            require(!pool4users[msg.sender].isExist, "you haven't purchased the pool before");
            pool4currUserID = pool4currUserID+1;
            pool4users[msg.sender] = PoolUserStruct(true,pool4currUserID,address(0),address(0));
            pool4userList[pool4currUserID]=msg.sender;
            if(pool4currUserID>=2){
                if(pool4users[pool4userList[pool4currUserID/2]].down1 == address(0)){
                    pool4users[pool4userList[pool4currUserID/2]].down1 = msg.sender;
                }
                
                else if(pool4users[pool4userList[pool4currUserID/2]].down2 == address(0)){
                    pool4users[pool4userList[pool4currUserID/2]].down2 = msg.sender;
                    dividePoolAmount(pool4userList[pool4currUserID/2],_poolNumber);
                    pool4users[pool4userList[pool4currUserID/2]].isExist = false;
                }
            }
        }
        if(_poolNumber==5){
            require(!pool5users[msg.sender].isExist, "you haven't purchased the pool before");
            pool5currUserID = pool5currUserID+1;
            pool5users[msg.sender] = PoolUserStruct(true,pool5currUserID,address(0),address(0));
            pool5userList[pool5currUserID]=msg.sender;
            if(pool5currUserID>=2){
                if(pool5users[pool5userList[pool5currUserID/2]].down1 == address(0)){
                    pool5users[pool5userList[pool5currUserID/2]].down1 = msg.sender;
                }
                
                else if(pool5users[pool5userList[pool5currUserID/2]].down2 == address(0)){
                    pool5users[pool5userList[pool5currUserID/2]].down2 = msg.sender;
                    dividePoolAmount(pool5userList[pool5currUserID/2],_poolNumber);
                    pool5users[pool5userList[pool5currUserID/2]].isExist = false;
                }
            }
        }
        if(_poolNumber==6){
            require(!pool6users[msg.sender].isExist, "you have purchased the pool before");
            pool6currUserID = pool6currUserID+1;
            pool6users[msg.sender] = PoolUserStruct(true,pool6currUserID,address(0),address(0));
            pool6userList[pool6currUserID]=msg.sender;
            if(pool6currUserID>=2){
                if(pool6users[pool6userList[pool6currUserID/2]].down1 == address(0)){
                    pool6users[pool6userList[pool6currUserID/2]].down1 = msg.sender;
                }
                
                else if(pool6users[pool6userList[pool6currUserID/2]].down2 == address(0)){
                    pool6users[pool6userList[pool6currUserID/2]].down2 = msg.sender;
                    dividePoolAmount(pool6userList[pool6currUserID/2],_poolNumber);
                    pool6users[pool6userList[pool6currUserID/2]].isExist = false;
                }
            }
        }
        if(_poolNumber==7){
            require(!pool7users[msg.sender].isExist, "you have purchased the pool before");
            pool7currUserID = pool7currUserID+1;
            pool7users[msg.sender] = PoolUserStruct(true,pool7currUserID,address(0),address(0));
            pool7userList[pool7currUserID]=msg.sender;
            if(pool7currUserID>=2){
                if(pool7users[pool7userList[pool7currUserID/2]].down1 == address(0)){
                    pool7users[pool7userList[pool7currUserID/2]].down1 = msg.sender;
                }
                
                else if(pool7users[pool7userList[pool7currUserID/2]].down2 == address(0)){
                    pool7users[pool7userList[pool7currUserID/2]].down2 = msg.sender;
                    dividePoolAmount(pool7userList[pool7currUserID/2],_poolNumber);
                    pool7users[pool7userList[pool7currUserID/2]].isExist = false;
                }
            }
        }
        if(_poolNumber==8){
            require(!pool8users[msg.sender].isExist, "you have purchased the pool before");
            pool8currUserID = pool8currUserID+1;
            pool8users[msg.sender] = PoolUserStruct(true,pool8currUserID,address(0),address(0));
            pool8userList[pool8currUserID]=msg.sender;
            if(pool8currUserID>=2){
                if(pool8users[pool8userList[pool8currUserID/2]].down1 == address(0)){
                    pool8users[pool8userList[pool8currUserID/2]].down1 = msg.sender;
                }
                
                else if(pool8users[pool8userList[pool8currUserID/2]].down2 == address(0)){
                    pool8users[pool8userList[pool8currUserID/2]].down2 = msg.sender;
                    dividePoolAmount(pool8userList[pool8currUserID/2],_poolNumber);
                    pool8users[pool8userList[pool8currUserID/2]].isExist = false;
                }
            }
        }
        if(_poolNumber==9){
            require(!pool9users[msg.sender].isExist, "you have purchased the pool before");
            pool9currUserID = pool9currUserID+1;
            pool9users[msg.sender] = PoolUserStruct(true,pool9currUserID,address(0),address(0));
            pool9userList[pool9currUserID]=msg.sender;
            if(pool9currUserID>=2){
                if(pool9users[pool9userList[pool9currUserID/2]].down1 == address(0)){
                    pool9users[pool9userList[pool9currUserID/2]].down1 = msg.sender;
                }
                
                else if(pool9users[pool9userList[pool9currUserID/2]].down2 == address(0)){
                    pool9users[pool9userList[pool9currUserID/2]].down2 = msg.sender;
                    dividePoolAmount(pool9userList[pool9currUserID/2],_poolNumber);
                    pool9users[pool9userList[pool9currUserID/2]].isExist = false;
                }
            }
        }
        
    }
    
    function dividePoolAmount(address _user,uint256 _poolNumber) internal{
            uint256 amount = PoolPrice[_poolNumber-1].mul(3);
                users[_user].withdrawWallet = users[_user].withdrawWallet.add(amount.div(2));
                users[_user].poolAmoutWithdrawn = users[_user].poolAmoutWithdrawn.add(amount.div(2));
            
            markettingWallet = markettingWallet.add(amount.div(2));
    }
    
    function finalizeData(address _user) public{
        
        users[_user].prevInvest = users[_user].invested;
        users[_user].invested = 0;
        users[_user].hold = users[_user].prevInvest;
        users[_user].isExist = false;
        users[_user].withdrawn = 0;
        users[_user].startTime = 0;
        users[_user].referrer = address(0);
        users[_user].poolWallet = 0;
        users[_user].levelIncome = 0;
        users[_user].poolAmoutWithdrawn = 0;
        users[_user].ROIAmount = 0;
        users[_user].ROITime = 0;
    }
    
    function getDailyROI(address _user) public view returns(uint256){
        uint256 amount=0;
        if(users[_user].ROIAmount < users[_user].invested.mul(4)){
         amount = (users[_user].invested.mul(DAILY_ROI).mul(block.timestamp.sub(users[_user].ROITime)).div(100).div(TIME));
        if(users[_user].ROIAmount.add(amount)>=users[_user].invested.mul(4)){
         amount = (users[_user].invested.mul(4)).sub(users[_user].ROIAmount);
        }
        }
        return amount;
    }
    
    function getPoolWallet(address _user) public view returns(uint256){
        uint256 amount =getDailyROI(_user);
        return amount.div(2);
    }
    
    function giveROI(address _user) public{
        users[_user].poolWallet = users[_user].poolWallet.add(getPoolWallet(_user));
        markettingWallet = markettingWallet.add(getPoolWallet(_user));
        uint256 amount = getDailyROI(_user);
        users[_user].ROIAmount = users[_user].ROIAmount.add(amount);
        users[_user].withdrawWallet = users[_user].withdrawWallet.add(amount.div(2));
        if(amount>0)
        users[_user].ROITime = block.timestamp;
        
        
    }
    // function withdrawLevelIncome() public{
    //         incomes[msg.sender].levelIncomeEarned = incomes[msg.sender].levelIncomeEarned.add(users[msg.sender].levelIncome);
    //         msg.sender.transfer(users[msg.sender].levelIncome);
    //         users[msg.sender].levelIncome = 0;
            
    // }
    
    function withdrawAmount() public{
        giveROI(msg.sender);
        
        uint256 amount;
        if(users[msg.sender].withdrawWallet.add(users[msg.sender].withdrawn) > users[msg.sender].invested.mul(4)){
            amount = users[msg.sender].invested.mul(4).sub(users[msg.sender].withdrawn);
        }
        else{
            amount = users[msg.sender].withdrawn.add(users[msg.sender].withdrawWallet);
        }
        if(users[msg.sender].withdrawn>=users[msg.sender].invested.mul(4)){
            users[msg.sender].hold = users[msg.sender].hold.add(users[msg.sender].withdrawWallet);
        }
        else if(users[msg.sender].withdrawWallet.add(users[msg.sender].withdrawn)>=users[msg.sender].invested.mul(4)){
            users[msg.sender].hold = users[msg.sender].hold.add((users[msg.sender].withdrawWallet.add(users[msg.sender].withdrawn).sub(users[msg.sender].invested.mul(4))));
        }
        
        //transfer 20% to owner
        address(uint256(owner)).transfer(amount.mul(2).div(10));
        
        amount = amount.add(users[msg.sender].levelIncome);
        msg.sender.transfer(amount.sub(amount.mul(2).div(10)));
        
        users[msg.sender].withdrawn = users[msg.sender].withdrawn.add(amount);
        users[msg.sender].withdrawWallet = 0;
        
        incomes[msg.sender].levelIncomeEarned = incomes[msg.sender].levelIncomeEarned.add(users[msg.sender].levelIncome);
        users[msg.sender].levelIncome = 0;
        
        if(users[msg.sender].withdrawn==users[msg.sender].invested.mul(4) && users[msg.sender].hold == users[msg.sender].invested){
            finalizeData(msg.sender);
        } 
    }
    
    function reInvest() public payable{
        require(users[msg.sender].hold == users[msg.sender].prevInvest, "your id is still active");
        
        // user must have invested previously
        require(users[msg.sender].prevInvest>0,"you need to invest first");
        
        require((msg.value.sub(TRX.mul(10)))%10==0, "you must pay in multiple of 10");
        
        // 10 trx to admin
        address(uint256(owner)).transfer(TRX.mul(10));
        
        // amount paid must be greater than or equal to previously invested amount
        require(msg.value>=users[msg.sender].prevInvest.add(TRX.mul(10)), "low investment not allowed");
        
        // add hold amount and current amount
        uint256 investmentAmount = users[msg.sender].hold.add(msg.value.sub(TRX.mul(10)));
        
        users[msg.sender].hold = 0;
        
        // call invest
        _invest(msg.sender,users[msg.sender].referrer,investmentAmount);
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
