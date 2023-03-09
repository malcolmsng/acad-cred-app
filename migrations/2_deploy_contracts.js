const Credential = artifacts.require('Credential');
const Institution = artifacts.require('Institution');

module.exports = (deployer, network, accounts) => {
  deployer.deploy(Institution).then(function () {
    return deployer.deploy(Credential, Institution.address);
  });
};
