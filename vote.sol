pragma solidity ^0.4.11;

contract Ballot {
    struct Voter {
        uint weight; //計票的權重
        bool voted; //表示該人是否已投票
        address delegate; //被委托人
        uint vote; //投票提案的索引
    }

    struct Proposal {
        bytes32 name; //提案名稱
        uint voteCount; //得票數
    }

    address public chairperson; //投票發起者的錢包地址
    
    mapping(address => Voter) public voters; //為每個可能的地址存儲一個Voter
    
    Proposal[] public proposals; //建立一個Proposal結構類型的動態陣列
    
    uint public deadline; //截止時間

    //創建投票
    function Ballot(uint _duration, bytes32[] proposalNames) {
        chairperson = msg.sender; 
        
        deadline = now + _duration;

        for (uint i = 0; i < proposalNames.length; i++) {
            proposals.push(Proposal({
                name: proposalNames[i],
                voteCount: 0
            }));
        }
    }

    //賦予投票權
    function giveRightToVote(address voter) {
        require(now < deadline); //截止時間到期則中斷處理
        require(msg.sender == chairperson && !voters[voter].voted); //執行函數的不是投票發起者 或 指定的地址已經投過票 則中斷處理
        voters[voter].weight += 1;
    }

    //委託投票權
    function delegate(address to) {
        require(now < deadline); //截止時間到期則中斷處理
        Voter sender = voters[msg.sender];
        require(!sender.voted && sender.weight>0); //委託者已經投票 或 委託者無投票權 則中斷處理
        require(to != msg.sender); //被委託者為交易起者 則中斷處理


        while (voters[to].delegate != address(0)) {
            to = voters[to].delegate;
            require(to != msg.sender);
        }

        sender.voted = true;
        sender.delegate = to;
        Voter delegate = voters[to];
        if (delegate.voted) {
            proposals[delegate.vote].voteCount += sender.weight;
        } else {
            delegate.weight += sender.weight;
        }
    }

    //進行投票
    function vote(uint proposal) {
        require(now < deadline); //截止時間到期則中斷處理
        Voter sender = voters[msg.sender];
        require(!sender.voted && sender.weight>0); //投票者已經投票 或 投票者無投票權 則中斷處理
        sender.voted = true;
        sender.vote = proposal;

        proposals[proposal].voteCount += sender.weight;
    }

    //查詢獲勝提案編號、名稱及得票數
    function winningProposal() constant
            returns (uint winningProposal, bytes32 winnerName, uint winningVoteCount)
    {
        require(now >= deadline); //截止時間未到期則中斷處理
        winningVoteCount = 0;
        for (uint p = 0; p < proposals.length; p++) {
            if (proposals[p].voteCount > winningVoteCount) {
                winningVoteCount = proposals[p].voteCount;
                winningProposal = p;
            }
        }
        winnerName = proposals[winningProposal].name;
        require(winningVoteCount > 0); //無人投票則中斷處理
    }

}