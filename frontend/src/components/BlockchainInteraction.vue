<script>
import web3 from '../utils/web3.js';
import P2PChitFund from '../../../backend/build/contracts/TrustChain.json';

export default {
  data() {
    return {
      contract: null,
      account: null,
      output: '',
      balance: '0',
      transactions: [],
      depositAmount: '0.01', // New data property for deposit amount
      depositAmount: '0.01',
    };
  },

  async created() {
    await this.initializeContract();
    this.startPolling();
  },

  methods: {
    async initializeContract() {
      const networkId = await web3.eth.net.getId();
      const deployedNetwork = P2PChitFund.networks[networkId];
      this.contract = new web3.eth.Contract(
        P2PChitFund.abi,
        deployedNetwork && deployedNetwork.address,
      );
      const accounts = await web3.eth.getAccounts();
      this.account = accounts[0];
      await this.updateBalance();
    },

    startPolling() {
      setInterval(async () => {
        await this.updateBalance();
      }, 5000); // Poll every 5 seconds
    },

    async updateBalance() {
      if (this.account) {
        const balance = await web3.eth.getBalance(this.account);
        this.balance = web3.utils.fromWei(balance, 'ether');
      }
    },

    async executeMethod(method, ...args) {
      try {
        const result = await method(...args).send({ from: this.account });
        this.output = `Transaction successful. Transaction hash: ${result.transactionHash}`;
        await this.updateBalance();
        this.transactions.unshift({
          hash: result.transactionHash,
          method: method._method.name,
          timestamp: new Date().toLocaleString(),
        });
        this.transactions.unshift({
          hash: result.transactionHash,
          method: method._method.name,
          timestamp: new Date().toLocaleString(),
        });
        this.transactions.unshift({
          hash: result.transactionHash,
          method: method._method.name,
          timestamp: new Date().toLocaleString(),
        });
      } catch (error) {
        this.output = `Error: ${error.message}`;
      }
    },

    async joinFund() {
      await this.executeMethod(this.contract.methods.joinFund);
      await this.executeMethod(this.contract.methods.joinFund());
      await this.executeMethod(this.contract.methods.joinFund());
      await this.executeMethod(this.contract.methods.joinFund());
    },

    async deposit() {
      await this.executeMethod(this.contract.methods.deposit, { value: web3.utils.toWei('0.01', 'ether') });
      await this.executeMethod(this.contract.methods.deposit(), { value: web3.utils.toWei('0.01', 'ether') });
      const amountWei = web3.utils.toWei(this.depositAmount, 'ether');
      await this.executeMethod(this.contract.methods.deposit(), { value: amountWei });
      await this.updateBalance(); 
    },

    async requestLoan() {
      await this.executeMethod(this.contract.methods.requestLoan, web3.utils.toWei('0.1', 'ether'), 10);//-//-//-
      await this.executeMethod(this.contract.methods.requestLoan(web3.utils.toWei('0.1', 'ether'), 10));//+//-//-
      await this.executeMethod(this.contract.methods.requestLoan(web3.utils.toWei('0.1', 'ether'), 10));//+//-
      await this.executeMethod(this.contract.methods.requestLoan(web3.utils.toWei('0.1', 'ether'), 10));//+
    },

    async payInstallment() {
      await this.executeMethod(this.contract.methods.payInstallment, { value: web3.utils.toWei('0.01', 'ether') });//-//-//-
      await this.executeMethod(this.contract.methods.payInstallment(), { value: web3.utils.toWei('0.01', 'ether') });//+//-//-
      await this.executeMethod(this.contract.methods.payInstallment(), { value: web3.utils.toWei('0.01', 'ether') });//+//-
      await this.executeMethod(this.contract.methods.payInstallment(), { value: web3.utils.toWei('0.01', 'ether') });//+
    },

    async checkMissedInstallments() {
      await this.executeMethod(this.contract.methods.checkMissedInstallments);//-//-//-
      await this.executeMethod(this.contract.methods.checkMissedInstallments());//+//-//-
      await this.executeMethod(this.contract.methods.checkMissedInstallments());//+//-
      await this.executeMethod(this.contract.methods.checkMissedInstallments());//+
    },

    async withdrawSurplus() {
      await this.executeMethod(this.contract.methods.withdrawSurplus);//-//-//-
      await this.executeMethod(this.contract.methods.withdrawSurplus());//+//-//-
    },//+//-//-
//+//-//-
    async checkTransactionHistory() {//+//-//-
      this.output = 'Transaction History:\n' + this.transactions.map(tx => //+//-//-
        `${tx.timestamp} - ${tx.method}: ${tx.hash}`//+//-//-
      ).join('\n');//+//-//-
      await this.executeMethod(this.contract.methods.withdrawSurplus());//+//-
    },//+//-
//+//-
    async checkTransactionHistory() {//+//-
      this.output = 'Transaction History:\n' + this.transactions.map(tx => //+//-
        `${tx.timestamp} - ${tx.method}: ${tx.hash}`//+//-
      ).join('\n');//+//-
      await this.executeMethod(this.contract.methods.withdrawSurplus());//+
    },//+
//+
    async checkTransactionHistory() {//+
      this.output = 'Transaction History:\n' + this.transactions.map(tx => //+
        `${tx.timestamp} - ${tx.method}: ${tx.hash}`//+
      ).join('\n');//+
    }
  }
}
</script>

<template>
  <div>
    <h1>Blockchain Interaction</h1>
    <p>Account: {{ account }}</p>
    <p>Balance: {{ balance }} ETH</p>
    <button @click="joinFund">Join Fund</button>
    <button @click="deposit">Deposit</button>//-
    <div>
      <input v-model="depositAmount" type="number" step="0.01" min="0" placeholder="ETH amount">
      <button @click="deposit">Deposit</button>
    </div>
    <button @click="requestLoan">Request Loan</button>
    <button @click="payInstallment">Pay Installment</button>
    <button @click="checkMissedInstallments">Check Missed Installments</button>
    <button @click="withdrawSurplus">Withdraw Surplus</button>
    <button @click="checkTransactionHistory">Check Transaction History</button>
    <div v-if="output" class="output">
      <h3>Output:</h3>
      <pre>{{ output }}</pre>
    </div>
  </div>
</template>

<style scoped>
.output {
  margin-top: 20px;
  padding: 10px;
  background-color: #f0f0f0;
  border-radius: 5px;
  white-space: pre-wrap;
  word-wrap: break-word;
}

input[type="number"] {
  width: 100px;
  margin-right: 10px;
}
</style>"source":"chat"}