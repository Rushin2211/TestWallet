<template>
  <div id="app">
    <h1>Create Account</h1>

    <hr />

    <!-- Display newAddress and newPrivateKey if not null -->
    <div class="account-info" v-if="newAddress && newPrivateKey">
      <div class="warning">
        <h3> ⚠️The following is your new account, please remember your private key!
          Please keep your private key in a safe place!</h3>
      </div>

      <div class="icon-info">
        <h3>
          <i class="fas fa-address-card"></i> New Address:
          <button @click="copyToClipboard(newAddress)" class="copy-button">
            <i class="fas fa-copy"></i> Copy
          </button>
        </h3>

        <p>{{ newAddress }}</p>
      </div>

      <div class="icon-info">
        <h3>
          <i class="fas fa-key"></i> New Private Key:
          <button @click="copyToClipboard(newPrivateKey)" class="copy-button">
            <i class="fas fa-copy"></i> Copy
          </button>
        </h3>

        <p>{{ newPrivateKey }}</p>
      </div>
    </div>

    <br />
    <br />

    <!--CreateAccountButton-->
    <div class="createAccount">
      <button name="createAccount" id="createAccount-btn" @click="createAccount">
        {{createAccountButtonText}}
      </button>

      <br/>
      <br/>

      <button name="Exit"  id="exit-btn" v-on:click="Exit">Exit</button>

      <br/>

    </div>
  </div>
</template>

<script>
import Web3 from "web3";
import Swal from "sweetalert2";

const data = require('../script/config.json')

// const web3 = new Web3(new Web3.providers.HttpProvider("HTTP://172.31.100.218:7545"));
const web3 = new Web3(new Web3.providers.HttpProvider(data.web3ProviderUrl));

export default {
  name: "CreateAccountComponent",
  data() {
    return {
      newPrivateKey: null,
      newAddress: null,
      createAccountButtonText: 'Create Account'
    };
  },

  methods: {
    createAccount() {
      const newAccount = web3.eth.accounts.create();
      this.newAddress = newAccount.address;
      this.newPrivateKey = newAccount.privateKey;
      this.createAccountButtonText = "Create Again"
    },

    copyToClipboard(text) {
      const textarea = document.createElement("textarea");
      textarea.value = text;
      document.body.appendChild(textarea);
      textarea.select();
      document.execCommand("copy");
      document.body.removeChild(textarea);
      Swal.fire({
          position: "center",
          icon: "success",
          title: "Copied to clipboard!",
          showConfirmButton: false,
          timer: 800
      });
    },

    Exit() {
      setTimeout(this.BackToLoginPage, 600)
    },

    BackToLoginPage() {
      this.$router.push('/LogIn')
    },
  },
};
</script>

<!-- Add "scoped" attribute to limit CSS to this component only -->
<style scoped>
#app {
  font-family: "Avenir", Helvetica, Arial, sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  text-align: center;
  color: #2c3e50;
  margin-top: 60px;
}

hr {
  width: 340px;
}

#createAccount-btn {
  width: 230px;
  height: 60px;
  background-color: rgb(74, 148, 232);
  color: white;
  border-color: transparent;
  padding: 10px 20px;
  font-size: 20px;
  border-radius: 20px;
  box-shadow: 2px 2px 5px rgba(0, 0, 0, 0.2);
}

#createAccount-btn:hover {
  color: white;
  background-color: rgb(74, 148, 232);
}

#createAccount-btn:active {
  font-size: 21px;
  color: white;
  background-color: rgb(128, 128, 128);
}

#exit-btn {
  width: 230px;
  height: 60px;
  background-color: rgb(74, 148, 232);
  color: white;
  border-color: transparent;
  padding: 10px 20px;
  font-size: 20px;
  border-radius: 20px;
  box-shadow: 2px 2px 5px rgba(0, 0, 0, 0.2);
}

#exit-btn:hover {
  color: white;
  background-color: rgb(74, 148, 232);
}

#exit-btn:active {
  font-size: 21px;
  color: white;
  background-color: rgb(128, 128, 128);
}

.account-info {
  margin-top: 20px;
}

.warning {
  background-color: #f8d7da;
  color: #721c24;
  padding: 10px;
  border-radius: 5px;
  word-wrap: break-word;
  white-space: pre-wrap;
}

.icon-info {
  margin-bottom: 10px;
}

.copy-button {
  justify-content: center; /* 水平居中 */
  align-items: center; /* 垂直居中 */
  width: 70px;
  height: 25px;
  background: none;
  border: 1px solid #007bff;
  border-radius: 5px;
  color: #007bff;
  cursor: pointer;
  margin-left: 5px;
  font-size: 15px;

}

.copy-button:hover {
  background-color: lightblue;
  box-shadow: 2px 2px 5px rgba(0, 0, 0, 0.5);
}
.copy-button:active{
  transform: scale(0.95);
}
p {
  font-size: 20px;
  text-align: center;
  word-break: break-all;
}
hr{
  width: 100%;
}
</style>
