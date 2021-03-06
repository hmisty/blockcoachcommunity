function $i(id) {
	return document.getElementById(id);
}

function $n(id) {
	return document.getElementsByName(id);
}

function $t(id, text) {
	document.getElementById(id).innerText = text;
}

function parseParams(url) {
	var re = /([^&=]+)=?([^&]*)/g,
		decodeRE = /\+/g,
		decode = function (str) { return decodeURIComponent( str.replace(decodeRE, " ") ); };

	var f = function(query) {
		let params = {}, e;

		while ( e = re.exec(query) ) params[ decode(e[1]) ] = decode( e[2] );
		return params;
	};

	var query = typeof(url) == "undefined" ? "" : url.split("?")[1];
	return f(query);
}

function mask_address(address) {
	if (typeof(address) != "undefined") {
		return address.slice(0, 6) + "..." + address.slice(-4);
	} else {
		return "";
	}
}

/////////////////////////////////////////////////////////////
var account;
const decimals = 18; //hard coded for less func calls
var token;
var congress;

var connectMetaMask; //async function
var onload; //function

var tokenApprove; //function
var congressDeposit; //function
var congressWithdraw; //function

var congressProposeNewBudget; //function
var congressVoteForBudget; //function
var congressVoteAgainstBudget; //function
var congressClearVoteOnBudget; //function

var congressProposeNewOwner; //function
var congressVoteForOwner; //function
var congressVoteAgainstOwner; //function
var congressClearVoteOnOwner; //function

var congressProposeNewCongress; //function
var congressVoteForCongress; //function
var congressVoteAgainstCongress; //function
var congressClearVoteOnCongress; //function

connectMetaMask = async function () {
	// Modern dapp browsers...
	if (window.ethereum) {
		window.web3 = new Web3(ethereum);
		try {
			// Request account access if needed
			await ethereum.enable();
			// Acccounts now exposed
			console.log("web3 is now ready.");
			// Refresh the page.
			window.location.reload(); //This works.
		} catch (error) {
			// User denied account access...
			window.alert("Failed to connect to MetaMask. 无法连接到MetaMask.");
		}
	}
	// Legacy dapp browsers...
	else if (window.web3) {
		window.web3 = new Web3(web3.currentProvider);
		// Acccounts always exposed
		console.log("web3 is already there.");
	}
	// Non-dapp browsers...
	else {
		console.log('Non-Ethereum browser detected. You should consider trying MetaMask!');
		window.alert("No MetaMask detected. 请先安装MetaMask.");
	}

}

onload = function () {
	if (typeof window.web3 == "undefined" 
		&& typeof window.ethereum == "undefined") {
		// metamask not found
		$i("no-metamask").style.display = "block";
		return;
	} else {
		console.log("metamask detected.");
	}

	// show current user account
	account = web3.eth.defaultAccount;

	if (typeof account == "undefined") {
		// metamask not logged in
		$i("metamask-nologin").style.display = "block";
		return;
	} else if (account == null) {
		// metamask not connected
		$i("metamask-notconnected").style.display = "block";
		return;
	}

	var address_masked = mask_address(account);
	$t("user-masked", address_masked);
	$t("user", address_masked);

	// load contracts
	token = getTokenContract();
	congress = getCongressContract();

	// get and show current account balance
	token.balanceOf(account, (e, r) => {
		var totalBCS = r.toNumber() / Math.pow(10, 18);
		$t("balance", totalBCS);

		//define function tokenApprove
		tokenApprove = function() {
			var bcs = prompt("预授权多少贝壳(BCS)质押？How many BCS to approve?", totalBCS);
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
			var bcs = prompt("质押多少贝壳(BCS)？How many BCS to deposit?", totalBCS);
			if (bcs > 0) {
				var amount = bcs * Math.pow(10, decimals);
				congress.deposit(amount, (e, r) => {
					console.log("deposit " + amount + " shell amount returns (e,r):");
					console.log(e);
					console.log(r);
				});
			}
		};

	});

	// get and show stake in congress
	congress.checkMemberStake(account, (e, r) => {
		var stakeAmount = r.toNumber();
		var stakeBCS = stakeAmount / Math.pow(10, 18);
		$t("stake", stakeBCS);

		congressWithdraw = function() {
			var bcs = prompt("取回多少贝壳(BCS)？How many BCS to withdraw?", stakeBCS);
			if (bcs > 0) {
				var amount = bcs * Math.pow(10, decimals);
				congress.withdraw(amount, (e, r) => {
					console.log("withdraw " + amount + " shell amount returns (e,r):");
					console.log(e);
					console.log(r);
				});
			}
		};

	});

	// get and show total stake in congress
	congress.checkTotalStake((e, r) => {
		var bcs = r.toNumber() / Math.pow(10, 18);
		$t("total-stake", bcs);
	});

	/* --------------- on budget proposal ------------------- */

	// get and show approved budget in congress
	congress.budgetApproved((e, r) => {
		var bcs = r.toNumber() / Math.pow(10, 18);
		$t("approved-budget", bcs);
	});

	// get and show current budget proposal
	congress.budgetProposal((err, res) => {
		if (res[1] > 0) {
			$t("budget-proposal-id", res[0]);
			$t("budget-proposal-amount", res[1] / Math.pow(10, decimals));
			$t("budget-proposal-for", res[2] / Math.pow(10, decimals));
			$t("budget-proposal-against", res[3] / Math.pow(10, decimals));
			$i("check-budget-proposal").style.display = "none";
			$i("budget-proposal").style.display = "block";
			$i("no-budget-proposal").style.display = "none";
		} else {
			$i("check-budget-proposal").style.display = "none";
			$i("no-budget-proposal").style.display = "block";
			$i("budget-proposal").style.display = "none";
		}
	});

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

	/* --------------- on owner proposal ------------------- */

	// get and show approved owner in congress
	congress.ownerApproved((e, r) => {
		var addr = r;
		var masked = mask_address(addr);
		$t("approved-owner", masked);
	});

	// get and show current owner proposal
	congress.ownerProposal((e, r) => {
		if (r[1] != "0x0000000000000000000000000000000000000000") {
			$t("owner-proposal-id", r[0]);
			var addr = r[1];
			var masked_addr = mask_address(addr);
			$t("owner-proposal-address", masked_addr);
			$t("owner-proposal-for", r[2]);
			$t("owner-proposal-against", r[3]);
			$i("check-owner-proposal").style.display = "none";
			$i("owner-proposal").style.display = "block";
			$i("no-owner-proposal").style.display = "none";
		} else {
			$i("check-owner-proposal").style.display = "none";
			$i("no-owner-proposal").style.display = "block";
			$i("owner-proposal").style.display = "none";
		}
	});

	congressProposeNewOwner = function() {
		var address = prompt("提案新群主的地址？Address of new Owner to propose?", "");
		console.log("new owner address input: " + address);
		if (address > 0) {
			congress.proposeNewOwner(address, (e, r) => {
				console.log("approve new owner " + address + " returns (e,r):");
				console.log(e);
				console.log(r);
			});
		}
	};

	congressVoteForOwner = function() {
		congress.voteForNewOwner((e, r) => {
			console.log("vote for owner proposal returns (e,r):");
			console.log(e);
			console.log(r);
		});
	};

	congressVoteAgainstOwner = function() {
		congress.voteAgainstNewOwner((e, r) => {
			console.log("vote against owner proposal returns (e,r):");
			console.log(e);
			console.log(r);
		});
	};

	congressClearVoteOnOwner = function() {
		congress.clearVoteOnNewOwner((e, r) => {
			console.log("clear vote on owner proposal returns (e,r):");
			console.log(e);
			console.log(r);
		});
	};

	/* --------------- on congress proposal ------------------- */

	// get and show approved congress in congress
	congress.congressApproved((e, r) => {
		$t("approved-congress", mask_address(r));
	});

	// get and show current congress proposal
	congress.congressProposal((e, r) => {
		if (r[1] != "0x0000000000000000000000000000000000000000") {
			$t("congress-proposal-id", r[0]);
			$t("congress-proposal-address", mask_address(r[1]));
			$t("congress-proposal-for", r[2]);
			$t("congress-proposal-against", r[3]);
			$i("check-congress-proposal").style.display = "none";
			$i("congress-proposal").style.display = "block";
			$i("no-congress-proposal").style.display = "none";
		} else {
			$i("check-congress-proposal").style.display = "none";
			$i("no-congress-proposal").style.display = "block";
			$i("congress-proposal").style.display = "none";
		}
	});

	congressProposeNewCongress = function() {
		var address = prompt("提案新议会的地址？Address of new Congress to propose?", "");
		console.log("new congress address input: " + address);
		if (address > 0) {
			congress.proposeNewCongress(address, (e, r) => {
				console.log("approve new congress " + address + " returns (e,r):");
				console.log(e);
				console.log(r);
			});
		}
	};

	congressVoteForCongress = function() {
		congress.voteForNewCongress((e, r) => {
			console.log("vote for congress proposal returns (e,r):");
			console.log(e);
			console.log(r);
		});
	};

	congressVoteAgainstCongress = function() {
		congress.voteAgainstNewCongress((e, r) => {
			console.log("vote against congress proposal returns (e,r):");
			console.log(e);
			console.log(r);
		});
	};

	congressClearVoteOnCongress = function() {
		congress.clearVoteOnNewCongress((e, r) => {
			console.log("clear vote on congress proposal returns (e,r):");
			console.log(e);
			console.log(r);
		});
	};

	/* ------------------- end ------------------------- */

}

window.addEventListener('load', onload);

/////////////////////////////////////////////////////////////
// beggar implementation of i18n
const i18n = {
	"zh": {
		"text-no-metamask": "未检测到MetaMask。请先安装MetaMask。",
		"text-metamask-nologin": "MetaMask未登入。请先登入MetaMask。",
		"text-metamask-notconnected": "MetaMask未连接。请先连接MetaMask。",
		"text-connect-metamask": "连接到MetaMask",
		"text-welcome": "欢迎",
		"text-account": "当前账户：",
		"text-account-no-colon": "当前账户",
		"text-account-address": "账户地址：",
		"text-balance": "账户余额(贝壳)：",
		"text-member-congress": "会员代表大会",
		"text-stake": "你的投票权(质押贝壳)：",
		"text-check-budget": "检查预算提案情况...",
		"text-no-budget": "当前无预算提案",
		"text-on-budget": "预算",
		"text-budget": "当前预算提案：",
		"text-propose-budget": "提交预算提案",
		"text-check-owner": "检查新群主提案情况...",
		"text-no-owner": "当前无新群主提案",
		"text-on-owner": "群主",
		"text-owner": "当前新群主提案：",
		"text-propose-owner": "提交新群主提案",
		"text-check-congress": "检查新议会提案情况...",
		"text-no-congress": "当前无新议会提案",
		"text-on-congress": "议会",
		"text-congress": "当前新议会提案：",
		"text-propose-congress": "提交新议会提案",
		"text-approve": "质押预授权",
		"text-deposit": "质押贝壳",
		"text-withdraw": "取回贝壳",
		"text-proposal-id": "提案号：",
		"text-proposal-budget": "预算贝壳数量：",
		"text-proposal-owner": "新群主：",
		"text-proposal-congress": "新议会：",
		"text-votes-for": "赞成票数：",
		"text-votes-against": "反对票数：",
		"text-vote-for": "赞成",
		"text-vote-against": "反对",
		"text-clear-vote": "撤回投票",
		"text-total-stake": "总投票权(质押贝壳)：",
		"text-approved-budget": "已批准的可用预算：",
		"text-approved-owner": "已批准的新群主：",
		"text-approved-congress": "已批准的新议会：",
	}
};

// translate when Chinese is supported
// unless lang is forced to en in url query like ?lang=en
var url_lang = parseParams(location.href)["lang"];

if (url_lang == "zh" || url_lang != "en" && navigator.languages.indexOf("zh") > -1) {
	//change the language toggle menu item
	$t("language", "中文");

	for (name in i18n["zh"]) {
		$n(name).forEach((n) => { n.innerText = i18n["zh"][name] });
	}
}

