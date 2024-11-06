<script>
import web3 from '../utils/web3.js';
import P2PChitFund from '../../../backend/build/contracts/P2PChitFund.json';

export default {
  data() {
    return {
      contract: null,
      account: null,
    };
  },

  async created() {
    const networkId = await web3.eth.net.getId();
    const deployedNetwork = P2PChitFund.networks[networkId];
    this.contract = new web3.eth.Contract(
        P2PChitFund.abi,
        deployedNetwork && deployedNetwork.address,
    );
    const accounts = await web3.eth.getAccounts();
    this.account = accounts[0];
  },

  methods: {
    async joinFund() {
      await this.contract.methods.joinFund().send({ from: this.account });
    },

    async deposit() {
      await this.contract.methods.deposit().send({ from: this.account, value: web3.utils.toWei('0.01', 'ether') });
    },

    async requestLoan() {
      await this.contract.methods.requestLoan(web3.utils.toWei('0.1', 'ether'), 10).send({ from: this.account });
    },

    async payInstallment() {
      await this.contract.methods.payInstallment().send({ from: this.account, value: web3.utils.toWei('0.01', 'ether') });
    },

    async checkMissedInstallments() {
      await this.contract.methods.checkMissedInstallments().send({ from: this.account });
    },

    async withdrawSurplus() {
      await this.contract.methods.withdrawSurplus().send({ from: this.account });
    }
  }
}
</script>

<template>
  <div>
    <h1>Blockchain Interaction</h1>
    <button @click="joinFund">Get Accounts</button>
    <button @click="deposit">Deposit</button>
    <button @click="requestLoan">Request Loan</button>
    <button @click="payInstallment">Pay Installment</button>
    <button @click="checkMissedInstallments">Check Missed Installments</button>
    <button @click="withdrawSurplus">Withdraw Surplus</button>
  </div>
</template>