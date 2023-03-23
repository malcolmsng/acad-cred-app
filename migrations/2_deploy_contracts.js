const Credential = artifacts.require('Credential');
const Institution = artifacts.require('Institution');
const AcceptanceVoting = artifacts.require('AcceptanceVoting');


module.exports = (deployer, network, accounts) => {
  deployer.deploy(AcceptanceVoting, 1, 1).then(function () {
    return deployer.deploy(Institution, AcceptanceVoting.address);
  }).then(function () {
    return deployer.deploy(Credential, Institution.address);
  });
};
