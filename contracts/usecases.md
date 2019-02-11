# use cases

Role:
- owner (of contract BCShell)
- member (of contract BCParliament)

## Story Mint.

- Owner can request a new budget for being voted.

- Member can vote for the new budget requested.

When votes > 1/2, the new budget will be added to the approved budget for later use.

- Owner can mint within the budget.

## Story Upgrade Parliament.

- Owner can request to upgrade parliament.

- Member can vote for the new parliament.

When votes > 1/2, the parliament pointer will point to the new parliament contract.

## Story Change Owner.

- Anyone can request to change owner.

- Member can vote for the new owner.

When votes > 2/3, the owner will be changed.

P.S. Owner cannot stop the process.
