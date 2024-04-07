<template>
  <div id="app">
    <h1 id="userArea">User Area</h1>

    <p id="accountAddress">Account Address: {{ accountAddress }}</p>

    <p id="accountBalance">Account Balance: {{ accountBalance }} ETH</p>

    <hr/>
    <br/>

    <button id="transferBtn" v-on:click="Transfer">Transfer</button>

    <el-dialog title="Ethereum transfer" v-model="this.transferFlag" width="350px" center>
      <el-form v-model="transferFrom">
        <el-form-item label="To" :label-width="formLabelWidth">
          <el-input v-model="transferFrom.receiverAddress" autocomplete="off"
                    placeholder="Recipient's Address" style="width: 250px"></el-input>
        </el-form-item>

        <el-form-item label="Amount" :label-width="formLabelWidth">
          <el-input v-model="transferFrom.amount" autocomplete="off"
                    placeholder="Amount" style="width: 250px"></el-input>
        </el-form-item>
      </el-form>

      <div style="text-align: center; margin-top: 20px;">
        <el-button v-on:click="Cancel" style="margin-right: 20px; font-size: 16px;">
          Cancel
        </el-button>

        <el-button v-on:click="confirmTransfer" type="primary" style="font-size: 16px; padding: 12px 20px;">
          Confirm
        </el-button>
      </div>
    </el-dialog>

    <br/>
    <br/>

    <button id="exitBtn" v-on:click="Skip_to_Login_Component">Exit</button>
  </div>
</template>

<script>
import Web3 from 'web3'
import {isAddress} from "web3-validator";
import Swal from "sweetalert2";

const data = require('../script/config.json')

const web3 = new Web3(new Web3.providers.HttpProvider(data.web3ProviderUrl))

const userPrivateKey = localStorage.getItem('PrivateKey')

export default {
  name: 'UserInterface',

  data() {
    return {
      accountAddress: '',

      accountBalance: 0,

      transferFrom: {
        receiverAddress: null,
        amount: null,
      },

      transferFlag: false,

      formLabelWidth: "55px",
    }
  },

  methods: {
    async getBalance(address) {
      try {
        const balanceWei = await web3.eth.getBalance(address);

        return web3.utils.fromWei(balanceWei, 'ether');
      } catch (error) {
        console.error('Failed to obtain account balance:', error);
      }
    },

    Skip_to_Login_Component() {
      this.$router.push('/LogIn');
    },

    Transfer() {
      this.transferFrom.receiverAddress = null;
      this.transferFrom.amount = null;
      this.transferFlag = true
    },

    Cancel() {
      this.transferFlag = false
    },

    async confirmTransfer() {
      // alert(this.transferFrom.receiverAddress)
      // alert(web3.utils.fromWei(this.transferFrom.amount, 'ether'))

      if (this.transferFrom.receiverAddress === null) {
        this.showError("Please enter the recipient's address ")
      }

      if (this.transferFrom.amount === null) {
        this.showError("Please enter the amount")
      }

      if (this.transferFrom.amount <= 0) {
        this.showError("Amount must be a positive number")
      }

      if (this.transferFrom.amount > this.accountBalance) {
        this.showError("Your account balance is not sufficient")
      }

      if (!isAddress(this.transferFrom.receiverAddress)) {
        this.showError("Invalid Ethereum address")
      }

      try {
        const txCount = await web3.eth.getTransactionCount(this.accountAddress);

        const txObject = {
          nonce: txCount,
          gasPrice: web3.utils.toWei('3', 'gwei'),
          gasLimit: 300000,
          to: this.transferFrom.receiverAddress,
          value: web3.utils.toWei(this.transferFrom.amount, 'ether'),
        }

        const txSigned = await web3.eth.accounts.signTransaction(txObject, userPrivateKey)

        await web3.eth.sendSignedTransaction(txSigned.rawTransaction)

        this.transferFlag = false

        await Swal.fire({
          position: "center",
          icon: "success",
          title: "Transfer successful",
          showConfirmButton: false,
          timer: 1500
        });
        this.accountBalance = await this.getBalance(this.accountAddress)
      } catch (error) {
        this.showError('An error occurred during the transfer.Error info:' + error);
      }
    },

    showError(errorMessage) {
      this.$message.error({
        duration: 1500,
        message: errorMessage,
        offset: 50,
      });
    },

    UserHasRefreshed() {
      const UserHasRefreshed = localStorage.getItem('UserHasRefreshed');

      if (!UserHasRefreshed) {
        window.location.reload()
        localStorage.setItem('UserHasRefreshed', 'true');
      } else {
        localStorage.removeItem('UserHasRefreshed');
      }
    },
  },

  created() {
    this.UserHasRefreshed();
  },

  async mounted() {
    try {
      this.accountAddress = await web3.eth.accounts.privateKeyToAccount(userPrivateKey).address
    } catch (error) {
      this.showError("File to obtain the account address: " + error)
    }

    try {
      this.accountBalance = await this.getBalance(this.accountAddress)
    } catch (error) {
      this.showError("File to obtain the account balance: " + error)
    }

  }
};
</script>

<style scoped>
#app {
  font-family: "Avenir", Helvetica, Arial, sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  text-align: center;
  color: #2c3e50;
  margin-top: 60px;
}

#accountAddress {
  font-size: 18px;
}

#accountBalance {
  font-size: 18px;
}

hr {
  width: 600px;
}

#transferBtn {
  width: 50%; /* 设置按钮宽度为父元素宽度的一半 */
  max-width: 230px; /* 设置按钮最大宽度 */
  height: 70px;
  background-color: rgb(74, 148, 232);
  color: white;
  border-color: transparent;
  padding: 10px 20px;
  font-size: 20px; /* 使用vw单位使按钮字体大小随视口宽度变化 */
  box-shadow: 2px 2px 5px rgba(0, 0, 0, 0.2);
  border-radius: 20px;
}

#transferBtn:active {
  font-size: 22px; /* 使用vw单位使按钮字体大小随视口宽度变化 */
  background-color: rgb(128, 128, 128);
  transform: scale(0.95);
}

#exitBtn {
  width: 50%; /* 设置按钮宽度为父元素宽度的一半 */
  max-width: 230px; /* 设置按钮最大宽度 */
  height: 70px;
  background-color: rgb(74, 148, 232);
  color: white;
  border-color: transparent;
  padding: 10px 20px;
  font-size: 20px; /* 使用vw单位使按钮字体大小随视口宽度变化 */
  box-shadow: 2px 2px 5px rgba(0, 0, 0, 0.2);
  border-radius: 20px;
}

#exitBtn:active {
  font-size: 22px; /* 使用vw单位使按钮字体大小随视口宽度变化 */
  background-color: rgb(128, 128, 128);
  transform: scale(0.95);
}
</style>