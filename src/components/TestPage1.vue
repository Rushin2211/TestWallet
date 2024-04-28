<template>
  <div class="fixed-header">
    <h1 class="page-title">WiFi-NFT Auction House</h1>
    <p class="show-balance">Your balance: {{ accountBalance !== null ? Math.floor(accountBalance * 1000000) / 1000000
        : accountBalance}}ETH</p>
  </div>

  <div v-if="isBidding" class="loading-overlay">
    <div class="progress">
      <div class="inner"></div>
      <div class="inner"></div>
      <div class="inner"></div>
      <div class="inner"></div>
      <div class="inner"></div>
    </div>
    <div class="loading-text">Bidding in progress, please wait...</div>
  </div>

  <div v-if="isEndAuction" class="loading-overlay">
    <div class="progress">
      <div class="inner"></div>
      <div class="inner"></div>
      <div class="inner"></div>
      <div class="inner"></div>
      <div class="inner"></div>
    </div>
    <div class="loading-text">Auction is ending, please wait...</div>
  </div>

  <div v-if="isWithdraw" class="loading-overlay">
    <div class="progress">
      <div class="inner"></div>
      <div class="inner"></div>
      <div class="inner"></div>
      <div class="inner"></div>
      <div class="inner"></div>
    </div>
    <div class="loading-text">Your bid is being withdrawn, please wait...</div>
  </div>

  <div class="auction-container">
    <div class="auction-info">
      <div v-if="noAuctionNFT" class="no-auction-nft-message">
        <p>There are no NFTs currently being auctioned.</p>
      </div>
      <div class="auction-item" v-for="(item, index) in Object.keys(this.auctionedNFTsInfoMap)" :key="index">
        <div class="item-header">
          <br/>
          <h3>NFT ID: {{ item }}</h3>
          <p>AP ID: {{ this.auctionedNFTsInfoMap[item].ApId }}</p>
          <p>NFT Duration: {{ DurationTime(this.auctionedNFTsInfoMap[item].nftDuration) }}</p>
        </div>
        <div class="item-details">
          <div class="beneficiary-container">
            <p>Beneficiary: {{ truncateAddress(this.auctionedNFTsInfoMap[item].beneficiary) }}</p>
            <button @click="copyToClipboard(this.auctionedNFTsInfoMap[item].beneficiary)"
                    class="copy-beneficiaries-button">
              <i class="fas fa-copy"></i> Copy
            </button>
          </div>
          <p>Starting Price: {{ this.auctionedNFTsInfoMap[item].startingPrice }}ETH</p>
          <div class="highestBidders-container">
            <p> Highest Bidder: {{ this.truncateAddress(this.auctionedNFTsInfoMap[item].highestBidder) }}</p>
            <button @click="copyToClipboard(this.auctionedNFTsInfoMap[item].highestBidder)"
                    class="copy-highest-bidder-button">
              <i class="fas fa-copy"></i> Copy
            </button>
          </div>
          <p>Highest Price: {{ this.auctionedNFTsInfoMap[item].highestPrice }}ETH</p>
          <p>Auction End Time: {{
              this.convertUnixTimestamp(Number(this.auctionedNFTsInfoMap[item].auctionEndTime))
            }}</p>

          <div v-if="this.auctionedNFTsInfoMap[item].refundPending!==0">
            <p>Your Pending Refund: {{ this.auctionedNFTsInfoMap[item].refundPending }}ETH</p>
          </div>
        </div>

        <div class="auction-buttons">
          <button @click="Bid(item)"
                  v-if="this.isBidDisabled||
                  new Date().getTime() / 1000>this.auctionedNFTsInfoMap[item].auctionEndTime||
                  this.auctionedNFTsInfoMap[item].highestBidder===this.address"
                  class="bid-button-disable" disabled>Bid
          </button>
          <button @click="Bid(item)" v-else class="bid-button">Bid</button>

          <button @click="Withdraw(item)"
                  v-if="this.isWithdrawDisabled||this.auctionedNFTsInfoMap[item].refundPending===0"
                  class="withdraw-button-disable" disabled>
            Withdraw
          </button>
          <button @click="Withdraw(item)" v-else class="withdraw-button">Withdraw</button>

          <button @click="endAuction(item)"
                  v-if="this.isEndAuctionDisabled||(new Date().getTime() / 1000)-50<this.auctionedNFTsInfoMap[item].auctionEndTime"
                  class="end-auction-button-disable"
                  disabled>End
          </button>
          <button @click="endAuction(item)" v-else class="end-auction-button">End</button>
        </div>
      </div>
    </div>
  </div>

  <br/>

  <div class="footer">
    <div class="button-container">
      <button @click="goBack()" class="go-back-button">Go Back</button>
    </div>
  </div>
</template>

<script>
import Swal from "sweetalert2";
import Web3 from "web3";

const data = require('../script/config.json')

const web3 = new Web3(new Web3.providers.HttpProvider(data.web3ProviderUrl));

const contractAddress = data.contractAddress;

const contractAbi = require("../script/sony.json");
export default {
  name: "AuctionInfo",
  data() {
    return {
      currentAuctionNFTs: [],

      contractInstance: null,

      accountAddress: null,

      auctionNFTNumber: '',

      currentAuctionNFTsResult: [],

      nftIds: Array,
      noAuctionNFT: false,
      allAuctionNFTNumber: null,
      isBidDisabled: false,
      isWithdrawDisabled: false,
      isEndAuctionDisabled: false,
      Role: '',
      privateKey: '',
      auctionedNFTsInfoMap: {},
      isBidding: false,
      isWithdraw: false,
      isEndAuction: false,
      accountBalance:null,
    }
  },

  async mounted() {
    this.JudgeIdentity();
    this.accountAddress = web3.eth.accounts.privateKeyToAccount(this.privateKey).address;
    this.accountBalance = this.getBalance(this.accountAddress)
        .then((balance) => {
          this.accountBalance = balance;
        })
        .catch((error) => {
          Swal.fire({
            icon: "error",
            title: "Network Error!",
            text: "Failed to connect to blockchain network!",
            footer: "Exception info:" + error.message
          });
        });
    this.contractInstance = await this.createContractInstance(contractAbi, contractAddress);
    await this.getCurrentAuctionNFTs(this.address);

    this.DurationTime()
  },

  methods: {
    DurationTime(Duration) {
      for(let i = 0; i < this.allAuctionNFTNumber; i++) {
        const DurationTime = Number(Duration);

        const DurationTime_Day = Math.trunc(DurationTime / 86400)
        const DurationTime_Hour = (DurationTime - DurationTime_Day * 86400) / 3600

        return DurationTime_Day + 'D' + ' ' + DurationTime_Hour + 'h'
      }
    },

    async getBalance(address) {
      try {
        const balanceWei = await web3.eth.getBalance(address);

        return web3.utils.fromWei(balanceWei, 'ether');
      } catch (error) {
        console.error('Failed to obtain account balance:', error);
      }
    },

    JudgeIdentity() {
      this.Role = localStorage.getItem("Role");
      if (this.Role === 'user') {
        this.isBidDisabled = false
        this.isWithdrawDisabled = false
        this.isEndAuctionDisabled = true
        this.privateKey = localStorage.getItem("PrivateKey");
      } else if (this.Role === 'admin') {
        this.isBidDisabled = true
        this.isWithdrawDisabled = true
        this.isEndAuctionDisabled = false
        this.privateKey = localStorage.getItem("AdministratorPrivateKey");
      }
    },

    async createContractInstance(abi, contractAddress) {
      return new Promise((resolve) => {
        const contractInstance = new web3.eth.Contract(abi, contractAddress);
        resolve(contractInstance);
      });
    },

    // todo
    async getCurrentAuctionNFTs() {
      await this.fetchCurrentAuctionNFTs();
      setInterval(async () => {
        await this.fetchCurrentAuctionNFTs();
      }, 5000);
    },

    // todo
    async fetchCurrentAuctionNFTs() {
      this.currentAuctionNFTs = await this.contractInstance.methods.getAuctionNFTList().call()
      this.currentAuctionNFTs.sort(function(a, b) {
        return Number(a - b);
      });
      console.log(this.currentAuctionNFTs)
      this.auctionNFTNumber = this.currentAuctionNFTs.length;
      for(let i = 1; i < this.auctionNFTNumber + 1; i++) {
        const currentAuctionNFTs = await this.contractInstance.methods.nftAuctionInfo(i).call()
        console.log(currentAuctionNFTs)
      }

    },

    // todo
    async Bid(tokenId) {
      try {
        const bidAmount = await Swal.fire({
          titleText: "Bid amount input ",
          html: `
      <input id="swal-input" class="swal2-input" placeholder="Unit: Ether">`,
          showCancelButton: true,
          inputAutoFocus: true,
          confirmButtonText: "Bid",
          confirmButtonColor: "red",
          showCloseButton: true,
          preConfirm: () => {
            return [
              document.getElementById("swal-input").value,
            ];
          }
        });
        if (bidAmount.isConfirmed) {
          if (bidAmount.value <= this.auctionedNFTsInfoMap[tokenId].startingPrice) {
            this.showError("Your bid must be greater than the starting bid!");
            return;
          }
          if (bidAmount.value + this.auctionedNFTsInfoMap[tokenId].refundPending <=
              this.auctionedNFTsInfoMap[tokenId].highestPrice) {
            this.showError("Your bid must be greater than the current highest bid!");
            return
          }
          this.isBidding = true;
          const txCount = await web3.eth.getTransactionCount(this.address);
          const bidInstance = this.contractInstance.methods.bid(Number(tokenId));
          const bidInstanceABI = bidInstance.encodeABI();
          const txObject = {
            nonce: txCount,
            to: contractAddress,
            value: web3.utils.toWei(Number(bidAmount.value), 'ether'),
            gasLimit: 3000000,
            gasPrice: web3.utils.toWei('2', 'gwei'),
            data: bidInstanceABI
          };
          const signed = await web3.eth.accounts.signTransaction(txObject, this.privateKey);
          await web3.eth.sendSignedTransaction(signed.rawTransaction);
          await this.fetchCurrentAuctionNFTs(this.address);
          this.isBidding = false;
          Swal.fire({
            position: "center",
            icon: "success",
            title: "Bid successful!",
            showConfirmButton: false,
            timer: 2500
          });
        }

      } catch (error) {
        console.error("Error:", error.message);
        const Toast = Swal.mixin({
          toast: true,
          position: "top",
          showConfirmButton: false,
          timer: 1500,
          timerProgressBar: false,
          didOpen: (toast) => {
            toast.onmouseenter = Swal.stopTimer;
            toast.onmouseleave = Swal.resumeTimer;
          }
        });
        Toast.fire({
          icon: "error",
          title: "Bid failed, please try again! Error message: " + error.message
        });
      } finally {
        this.accountBalance = this.getBalance(this.address)
            .then((balance) => {
              this.accountBalance = balance;
            })
            .catch((error) => {
              Swal.fire({
                icon: "error",
                title: "Network Error!",
                text: "Failed to connect to blockchain network!",
                footer: "Exception info:" + error.message
              });
            });
        this.isBidding = false;
      }
    },

    // todo
    async Withdraw(tokenId) {
      try {
        Swal.fire({
          text: "Do you want to withdraw your pending refund?",
          icon: "question",
          showCancelButton: true,
          confirmButtonColor: "#3085d6",
          cancelButtonColor: "orange",
          confirmButtonText: "Confirm"
        }).then(async (result) => {
          if (result.isConfirmed) {
            this.isWithdraw = true;
            const txCount = await web3.eth.getTransactionCount(this.address);
            const withdrawInstance = this.contractInstance.methods.withdraw(Number(tokenId));
            const withdrawInstanceEncodedABI = withdrawInstance.encodeABI();
            const txObject = {
              nonce: txCount,
              to: contractAddress,
              gasLimit: 3000000,
              gasPrice: web3.utils.toWei('2', 'gwei'),
              data: withdrawInstanceEncodedABI
            };
            const signed = await web3.eth.accounts.signTransaction(txObject, this.privateKey);
            await web3.eth.sendSignedTransaction(signed.rawTransaction);
            await this.fetchCurrentAuctionNFTs(this.address);
            this.isWithdraw = false;
            Swal.fire({
              position: "center",
              icon: "success",
              title: "Your bid was successfully withdrawn!",
              showConfirmButton: false,
              timer: 2500
            });
          }
        })

      } catch (error) {
        console.error("Error:", error.message);
        const Toast = Swal.mixin({
          toast: true,
          position: "top",
          showConfirmButton: false,
          timer: 1500,
          timerProgressBar: false,
          didOpen: (toast) => {
            toast.onmouseenter = Swal.stopTimer;
            toast.onmouseleave = Swal.resumeTimer;
          }
        });
        Toast.fire({
          icon: "error",
          title: "Bid failed, please try again! Error message: " + error.message
        });
      } finally {
        this.accountBalance = this.getBalance(this.address)
            .then((balance) => {
              this.accountBalance = balance;
            })
            .catch((error) => {
              Swal.fire({
                icon: "error",
                title: "Network Error!",
                text: "Failed to connect to blockchain network!",
                footer: "Exception info:" + error.message
              });
            });
        this.isWithdraw = false;
      }
    },

    // todo
    async endAuction(tokenId) {
      try {
        Swal.fire({
          text: "Do you want to end this auction?",
          icon: "question",
          showCancelButton: true,
          confirmButtonColor: "#3085d6",
          cancelButtonColor: "orange",
          confirmButtonText: "Confirm"
        }).then(async result => {
          if (result.isConfirmed) {
            this.isEndAuction = true;
            const txCount = await web3.eth.getTransactionCount(this.address);
            const withdrawInstance = this.contractInstance.methods.auctionEnd(Number(tokenId));
            const auctionEndInstance = withdrawInstance.encodeABI();
            const txObject = {
              nonce: txCount,
              to: contractAddress,
              gasLimit: 3000000,
              gasPrice: web3.utils.toWei('2', 'gwei'),
              data: auctionEndInstance
            };

            const signed = await web3.eth.accounts.signTransaction(txObject, this.privateKey);
            await web3.eth.sendSignedTransaction(signed.rawTransaction);
            this.isEndAuction = false;
            delete this.auctionedNFTsInfoMap[tokenId]
            Swal.fire({
              position: "center",
              icon: "success",
              title: "Successfully ended the current auction!",
              showConfirmButton: false,
              timer: 2500
            });
          }
        });
      } catch (error) {
        console.error("Error:", error.message);
        const Toast = Swal.mixin({
          toast: true,
          position: "top",
          showConfirmButton: false,
          timer: 15000,
          timerProgressBar: false,
          didOpen: (toast) => {
            toast.onmouseenter = Swal.stopTimer;
            toast.onmouseleave = Swal.resumeTimer;
          }
        });
        Toast.fire({
          icon: "error",
          title: "Bid failed, please try again! Error message: " + error.message
        });
      } finally {
        this.accountBalance = this.getBalance(this.address)
            .then((balance) => {
              this.accountBalance = balance;
            })
            .catch((error) => {
              Swal.fire({
                icon: "error",
                title: "Network Error!",
                text: "Failed to connect to blockchain network!",
                footer: "Exception info:" + error.message
              });
            });
        this.isEndAuction = false;
      }
    },

    convertUnixTimestamp(unixTimestamp) {
      const date = new Date(unixTimestamp * 1000);
      return date.toLocaleString();
    },

    truncateAddress(address) {
      if (address === this.address) {
        return 'yourself'
      }
      if (address !== undefined) {
        return address.slice(0, 4) + '...' + address.slice(-4);
      }
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

    goBack() {
      if (this.Role === 'admin') {
        this.$router.push('/AdminInterface')
      } else {
        this.$router.push('/UserInterface')
      }
    },

    showError(message) {
      this.$message.error({
        duration: 1500,
        message,
        offset: 50,
      });
    },
  },
}
</script>

<style scoped>

.fixed-header {
  position: fixed;
  top: 0;
  left: 50%;
  transform: translateX(-50%);
  width: 100%;
  background-color: #ffffff;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0);
  padding: 10px 20px;
  z-index: 1000;
}

.page-title {
  text-align: center;
  font-size: 28px;
  font-weight: bold;
  margin: 0;
  color: #333333;
}

.show-balance {
  font-size: 16px;
  margin-top: 5px;
  color: #666666;
}
.auction-info {
  display: flex;
  flex-wrap: wrap;
  justify-content: center; /* Center items horizontally */
}

.auction-container {
  margin-top: 120px;
  display: flex;
  flex-wrap: wrap;
  justify-content: center;
}

.auction-item {
  border-radius: 10px; /* Rounded edges */
  padding: 20px;
  margin: 35px; /* Add margin to separate cards and remove the gap */
  background-color: #f3f4f6; /* Light gray background */
  box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1); /* Slight shadow */
  /*flex-grow: 0; !* Make each card grow to fill available space *!*/
  min-width: 300px; /* Set minimum width for each card */
  flex: 0 0 calc(25% - 10px); /* 设置每个卡片的宽度，考虑到间距 */
  /*margin: 5px; !* 设置卡片间距 *!*/
}

.item-header {
  background: #99bad5; /* Blue background */
  border-radius: 10px;
  padding-bottom: 10px;
}

.item-header h3 {
  margin: 0;
  font-size: 18px;
  text-align: center;
  color: black;
}

.item-details {
  margin-top: 10px;
  border-radius: 10px;
  padding-bottom: 10px;
  text-align: center;
  background: #d2eed2;
}

.item-details p {
  margin: 5px 0;
  font-size: 16px;
  color: black; /* Dark gray text */
}

.beneficiary-container,
.highestBidders-container {
  display: flex;
  align-items: center;
  justify-content: center;
}

.copy-beneficiaries-button,
.copy-highest-bidder-button {
  width: 30px;
  height: 15px;
  background: none;
  border: 1px solid #ffffff; /* White border */
  border-radius: 5px;
  color: black; /* White text */
  cursor: pointer;
  font-size: 8px;
  margin-left: 5px;
}

.copy-beneficiaries-button :hover {
  background-color: lightblue; /* 设置悬停时的背景色为浅蓝色 */
  box-shadow: 2px 2px 5px rgba(0, 0, 0, 0.5);
}

.copy-highest-bidder-button :hover {
  background-color: lightblue; /* 设置悬停时的背景色为浅蓝色 */
  box-shadow: 2px 2px 5px rgba(0, 0, 0, 0.5);
}

.copy-beneficiaries-button :active {
  transform: scale(0.95);
}

.copy-highest-bidder-button :active {
  transform: scale(0.95);
}

.auction-buttons {
  display: flex;
  justify-content: space-between; /* Evenly distribute buttons */
  margin-top: 10px; /* Add some spacing between buttons and details */
}

.auction-buttons button {
  flex: 1; /* Make buttons equally distribute available space */
  margin: 0 5px; /* Add margin to separate buttons */
  padding: 10px;
  border: none;
  border-radius: 5px;
  cursor: pointer;
  font-size: 16px;
  transition: background-color 0.3s ease;
}

.auction-buttons button:hover {
  background-color: #4a90e2; /* Darker shade of blue on hover */
  color: #ffffff; /* White text on hover */
}

.auction-buttons button:active {
  transform: scale(0.96);
}

.bid-button {
  background-color: #b8e994; /* Light green */
}

.bid-button-disable {
  color: white;
  background-color: gray; /* Light green */
  pointer-events: none;
}

.withdraw-button {
  background-color: #ff7979; /* Light red */
}

.withdraw-button-disable {
  color: white;
  background-color: gray; /* Light green */
  pointer-events: none;
}

.end-auction-button {
  background-color: #ffbe76; /* Light orange */
}

.end-auction-button-disable {
  color: white;
  background-color: gray; /* Light green */
  pointer-events: none;
}

.go-back-button {
  width: 200px;
  background-color: #4CAF50; /* Green */
  border: none;
  color: white;
  padding: 15px 0;
  text-align: center;
  text-decoration: none;
  font-size: 16px;
  margin: 0 auto;
  cursor: pointer;
  border-radius: 8px;
  transition: background-color 0.3s ease;
}

.button-container {
  display: block;
}

.go-back-button:hover {
  background-color: #45a049; /* Darker Green */
}

.go-back-button:active {
  transform: scale(0.96);
}

.footer {
  position: relative;
  top: 10px;
  left: 0;
  margin-bottom: 20px;
  width: 100%;
  text-align: center;
}

.no-auction-nft-message {
  text-align: center; /* 居中文本 */
  margin-top: 20px; /* 添加一些顶部间距 */
  padding: 20px; /* 添加一些内边距 */
  background-color: #f5dcdc; /* 背景颜色 */
  border-radius: 8px; /* 圆角边框 */
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1); /* 阴影效果 */
  font-size: 20px;
}

.loading-overlay {
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background: rgba(255, 255, 255, 0.8);
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  z-index: 9999;
}

.loading-text {
  color: #329f32;
  font-size: 20px;
  margin-top: 55px;
  text-align: center;
}

.progress {
  position: fixed;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  display: flex;
  gap: 5px;
  align-items: center;
  justify-content: center;
  text-align: center;
  width: 300px;
  backface-visibility: hidden;
}
.inner:nth-child(1),
.inner:nth-child(2),
.inner:nth-child(3),
.inner:nth-child(4),
.inner:nth-child(5) {
  height: 20px;
  width: 20px;
  border-radius: 3px;
  animation: progress 1.2s ease-in infinite;
}

.inner:nth-child(1) {
  background-color: #2193b0;
  animation-delay: 0.15s;
}

.inner:nth-child(2) {
  background-color: #48b1bf;
  animation-delay: 0.25s;
}

.inner:nth-child(3) {
  background-color: #56ab2f;
  animation-delay: 0.35s;
}

.inner:nth-child(4) {
  background-color: #614385;
  animation-delay: 0.45s;
}

.inner:nth-child(5) {
  background-color: #185a9d;
  animation-delay: 0.55s;
}

@keyframes progress {
  0% {
    transform: translateY(0px);
    opacity: 1;
  }

  50% {
    transform: translateY(-60px);
    opacity: 0.8;
  }

  100% {
    transform: translateY(0px);
    opacity: 1;
  }
}

@media screen and (max-width: 768px) {
  .auction-item,
  .go-back-button {
    width: calc(50% - 40px); /* Set width to 50% for screens smaller than 768px */
  }
}

@media screen and (max-width: 480px) {
  .auction-item,
  .go-back-button {
    width: calc(100% - 40px); /* Set width to 100% for screens smaller than 480px */
  }
}
</style>
