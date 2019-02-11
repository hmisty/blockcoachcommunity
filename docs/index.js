function $(id) {
	return document.getElementById(id);
}

function $$(id, text) {
	document.getElementById(id).innerText = text;
}

var account;
const decimals = 18; //hard coded for less func calls
var token;
var congress;

var tokenApprove; //function
var congressDeposit; //function
var congressProposeNewBudget; //function
var congressVoteForBudget; //function
var congressVoteAgainstBudget; //function
var congressClearVoteOnBudget; //function

window.addEventListener('load', function() {
	if (typeof web3 == "undefined") {
		$("no-metamask").style.display = "block";
	} else {
		console.log("web3 is ready");

		token = getTokenContract();
		congress = getCongressContract();

		// show current user account
		account = web3.eth.defaultAccount;
		$$("user", account);

		// get and show current account balance
		token.balanceOf(account, (e, r) => {
			var bcs = r.toNumber() / Math.pow(10, 18);
			$$("balance", bcs);
		});

		//define function tokenApprove
		tokenApprove = function() {
			var bcs = prompt("预授权质押多少贝壳(BCS)？How many BCS to approve?", 0);
			if (bcs > 0) {
				var amount = bcs * Math.pow(10, decimals);
				token.approve(congress.address, amount, (e, r) => {
					console.log("approve " + amount + " shell amount returns (e,r):");
					console.log(e);
					console.log(r);
				});
			}
		};

		congressDeposit = function() {
			var bcs = prompt("质押多少贝壳(BCS)？How many BCS to deposit?", 0);
			if (bcs > 0) {
				var amount = bcs * Math.pow(10, decimals);
				congress.deposit(amount, (e, r) => {
					console.log("deposit " + amount + " shell amount returns (e,r):");
					console.log(e);
					console.log(r);
				});
			}
		};

		congressProposeNewBudget = function() {
			var bcs = prompt("提案新增多少贝壳(BCS)的预算？How many new BCS to propose?", 0);
			if (bcs > 0) {
				var amount = bcs * Math.pow(10, decimals);
				congress.proposeNewBudget(amount, (e, r) => {
					console.log("approve " + amount + " shell amount returns (e,r):");
					console.log(e);
					console.log(r);
				});
			}
		};

		congressVoteForBudget = function() {
			congress.voteForNewBudget((e, r) => {
					console.log("vote for budget proposal returns (e,r):");
					console.log(e);
					console.log(r);
			});
		};

		congressVoteAgainstBudget = function() {
			congress.voteAgainstNewBudget((e, r) => {
					console.log("vote against budget proposal returns (e,r):");
					console.log(e);
					console.log(r);
			});
		};

		congressClearVoteOnBudget = function() {
			congress.clearVoteOnNewBudget((e, r) => {
					console.log("clear vote on budget proposal returns (e,r):");
					console.log(e);
					console.log(r);
			});
		};

		// get and show stake in congress
		congress.checkMemberStake(account, (e, r) => {
			var bcs = r.toNumber() / Math.pow(10, 18);
			$$("stake", bcs);
		});

		// get and show total stake in congress
		congress.checkTotalStake((e, r) => {
			var bcs = r.toNumber() / Math.pow(10, 18);
			$$("total-stake", bcs);
		});

		// get and show approved budget in congress
		congress.budgetApproved((e, r) => {
			var bcs = r.toNumber() / Math.pow(10, 18);
			$$("approved-budget", bcs);
		});

		// get and show current budget proposal
		congress.budgetProposal((err, res) => {
			if (res[1] > 0) {
				$$("budget-proposal-id", res[0]);
				$$("budget-proposal-amount", res[1] / Math.pow(10, decimals));
				$$("budget-proposal-for", res[2] / Math.pow(10, decimals));
				$$("budget-proposal-against", res[3] / Math.pow(10, decimals));
				$("check-budget-proposal").style.display = "none";
				$("budget-proposal").style.display = "block";
				$("no-budget-proposal").style.display = "none";
			} else {
				$("check-budget-proposal").style.display = "none";
				$("no-budget-proposal").style.display = "block";
				$("budget-proposal").style.display = "none";
			}
		});
		

	}

});

// beggar implementation of i18n
const i18n = {
	"zh": {
		"text-no-metamask": "未检测到MetaMask。请先安装MetaMask。",
		"text-welcome": "欢迎来到教链社群",
		"text-account": "您的账户：",
		"text-balance": "您账户上的贝壳数量：",
		"text-congress": "会员代表大会",
		"text-stake": "您质押于投票权的贝壳数量：",
		"text-check-budget": "检查预算提案情况...",
		"text-no-budget": "当前无预算提案",
		"text-on-budget": "预算",
		"text-budget": "当前预算提案：",
		"text-propose-budget": "提交预算提案",
		"text-approve": "质押预授权",
		"text-deposit": "质押贝壳",
		"text-proposal-id": "提案号：",
		"text-proposal-budget": "预算贝壳数量：",
		"text-votes-for": "赞成票数：",
		"text-votes-against": "反对票数：",
		"text-vote-for": "赞成",
		"text-vote-against": "反对",
		"text-clear-vote": "撤回投票",
		"text-total-stake": "总质押贝壳数量：",
		"text-approved-budget": "已批准的可用预算：",
	}
};

// translate when Chinese is supported
if (navigator.languages.indexOf("zh") > -1) {
	for (id in i18n["zh"]) {
		$(id).innerText = i18n["zh"][id];
	}
}

