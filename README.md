# 教链社区
blockcoach community

## 去中心化自治组织
DAO, decentralized autonomous organization

**本社区治理的去中心化通过区块链实现Contract(智能合约) + Community Owner(群主) + Member Congress(议会)分立制约：群主可以解散议会，议会可以弹劾和改选群主；群主可以增发贝壳，但是只能在议会未解散且批准预算范围内。*

以上治理结构使用以太坊智能合约定义如下：

**链上权益证明：BCS, Blockcoach Community Shell，贝壳。**
1. 无预发行。所有贝壳只在社区成员贡献后，经President在Parliament批准和监督下按规则发行和分配。
2. 贝壳作为投票权。
3. 贝壳可以在链上自由流通（ERC-20标准资产）。

**链上角色：Community Owner(群主)**，由智能合约定义的权力为：
1. 指定议会（需要议会投票通过）。
2. 启动铸造新的贝壳(需要符合议会批准的预算)。
3. **(off-chain)**亲自或指定专人负责按照形成共识的“贡献-奖励”分配表将新增贝壳在区块链上进行分发。

**链上角色：Congress Member(议会成员)**，由智能合约定义的权力为：
1. 质押贝壳到议会，作为投票权。
2. 从议会取回质押的贝壳，投票权相应降低。
3. 启动Budget(预算)投票提案。
4. 启动更换Owner投票提案。
5. 投票支持Budget提案。正方获得50%权重票即自动生效，新预算累加到已批准预算。
6. 投票反对Budget提案。反方获得50%权重票即自动失败，预算提案归零。
7. 投票支持更换Owner的提案。正方获得50%权重票即自动生效，新Owner获得任职资格。
8. 投票反对更换Owner的提案。反方获得50%权重票即自动失败，提案归零。

**链上角色：Shell holder(持有贝壳的所有人)**，由区块链技术赋予的权利为：
1. 自由持有和交换贝壳。所有权由区块链保护。
2. 享受贝壳的实用权益，比如换取课程优惠券等。
3. 质押贝壳到议会，获得投票权。
