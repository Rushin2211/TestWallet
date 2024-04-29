<template>
    <div id="app">

        <h1>Login to Test Wallet</h1>

        <hr/>

        <br/>
        <br/>
        <br/>

        <div class="select-box-container">
            <div class="custom-radio">
                <input type="radio" id="user" name="role" v-model="selectedRole" value="user">
                <label for="user">User</label>

                <input type="radio" id="admin" name="role" v-model="selectedRole" value="admin">
                <label for="admin">Admin</label>
            </div>
        </div>

        <br/>
        <br/>

        <input
            type="password"
            name="text"
            class="pwd"
            placeholder="Please enter your password"
            id="password"
            v-model="password"/>

        <br/>
        <br/>

        <input
            type="checkbox"
            name="remember me"
            id="RememberMe"
            class="checkbox-group"
            @change="SaveUser"/>Remember me

        <br/>

        &nbsp; &nbsp;

        <input
            type="checkbox"
            name="ShowPassword"
            class="checkbox-group"
            id="ShowPwd"
            @change="handleChange"/>Show private key

        <br/>
        <br/>
        <br/>
        <br/>

        <div id="LoginBtn">
            <button name="login" id="login-btn" class="LoginBtn" v-on:click="login">Login</button>
        </div>

        <br/>
        <br/>

        Don't have an account? <a v-on:click="CreateAccountPage">Create now</a>

    </div>
</template>

<script>
import Swal from 'sweetalert2'
import Web3 from "web3";
import { isAddress } from 'web3-validator';

const data = require('../script/config.json')

const web3 = new Web3(new Web3.providers.HttpProvider(data.web3ProviderUrl));

let remember = false;

const savedUserPrivateKey = localStorage.getItem("userPrivateKey");

const savedAdminPrivateKey = localStorage.getItem("adminPrivateKey");

const contractAddress = data.contractAddress;

const sonyAbi = require("../script/sony.json");

export default {
    data() {
        return {
            contractInstance: null,

            selectedRole: 'user',

            password: '',

            ShowPwd: '',

            userCurrentPrivateKey: '',

            userSavedPrivateKey: '',
        };
    },

    async mounted() {
        // Retrieve password from local storage during page loading
        this.password = localStorage.getItem(`${this.selectedRole}PrivateKey`) || '';
        this.contractInstance = await this.createContractInstance(sonyAbi, contractAddress);
        web3.eth.net.isListening()
            .then(data => {
                this.networkError = false;
                console.log("Network Connected!")
            })
            .catch((error) => {
                this.networkError = true;
                Swal.fire({
                    icon: "error",
                    title: "Network Error!",
                    text: "Failed to connect to blockchain network!",
                    footer: "Exception info:" + error.message
                });
            });
    },

    watch: {
        selectedRole(newValue) {
            // Manually update password when options change
            this.password = localStorage.getItem(`${newValue}PrivateKey`) || '';
        },
    },

    methods: {
        handleChange() {
            const passwordField = document.getElementById("password");
            const toggleCheckbox = document.getElementById("ShowPwd");

            if (toggleCheckbox.checked) {
                passwordField.type = "text";
            } else {
                passwordField.type = "password";
            }
        },

        SaveUser: function () {
            const rememberCheckbox = document.getElementById("RememberMe");
            if (rememberCheckbox.checked) {
                remember = true;
            }
        },

        login: async function () {
            if (this.networkError) {
                await Swal.fire({
                    icon: "error",
                    title: "Network Error!",
                    text: "Failed to connect to blockchain network!",
                });
                return
            }
            if (this.selectedRole === 'user') {
                const userPrivateKeyInput = document.getElementById("password");
                const userPrivateKeyValue = this.addHexPrefix(userPrivateKeyInput.value);

                if (userPrivateKeyValue === savedUserPrivateKey &&
                    this.validateEthereumAddress(savedUserPrivateKey)) {

                    localStorage.removeItem("userTemporaryPrivateKey");

                    localStorage.setItem("userTemporaryPrivateKey", userPrivateKeyValue);

                    localStorage.removeItem("Role");

                    localStorage.setItem("Role", this.selectedRole);

                    const Toast = Swal.mixin({
                        toast: true,
                        position: "top",
                        showConfirmButton: false,
                        timer: 800,
                        timerProgressBar: false,
                        didOpen: (toast) => {
                            toast.onmouseenter = Swal.stopTimer;
                            toast.onmouseleave = Swal.resumeTimer;
                        }
                    });
                    Toast.fire({
                        icon: "success",
                        title: "Welcome back!"
                    });
                    setTimeout(this.UserInterfacePage, 600)
                } else if (userPrivateKeyValue.trim() === "") {
                    const Toast = Swal.mixin({
                        toast: true,
                        position: "top",
                        showConfirmButton: false,
                        timer: 800,
                        timerProgressBar: false,
                        didOpen: (toast) => {
                            toast.onmouseenter = Swal.stopTimer;
                            toast.onmouseleave = Swal.resumeTimer;
                        }
                    });
                    Toast.fire({
                        icon: "error",
                        title: "Please enter your private key!"
                    });
                } else if (userPrivateKeyValue !== savedUserPrivateKey &&
                    !this.validateEthereumAddress(userPrivateKeyValue)) {
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
                        title: "Private key is incorrect, please re-enter!"
                    });
                } else if (userPrivateKeyValue !== savedUserPrivateKey &&
                    this.validateEthereumAddress(userPrivateKeyValue) && !remember) {

                    localStorage.removeItem("userTemporaryPrivateKey");

                    localStorage.setItem("userTemporaryPrivateKey", userPrivateKeyValue);

                    localStorage.removeItem("Role");

                    localStorage.setItem("Role", this.selectedRole);

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
                        icon: "success",
                        title: "Login successfully!"
                    });

                    setTimeout(this.UserInterfacePage, 600)
                } else if (userPrivateKeyValue !== savedUserPrivateKey &&
                    this.validateEthereumAddress(userPrivateKeyValue) && remember) {

                    localStorage.removeItem("userPrivateKey");

                    localStorage.setItem("userPrivateKey", userPrivateKeyValue);

                    localStorage.removeItem("userTemporaryPrivateKey");

                    localStorage.setItem("userTemporaryPrivateKey", userPrivateKeyValue);

                    localStorage.removeItem("Role");

                    localStorage.setItem("Role", this.selectedRole);

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
                        icon: "success",
                        title: "Login successfully!"
                    });

                    setTimeout(this.UserInterfacePage, 600)
                } else {
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
                        title: "Private key is incorrect, please re-enter!"
                    });
                }

                this.JudgmentPrivateKey();

            } else if (this.selectedRole === 'admin') {
                const adminPrivateKeyInput = document.getElementById("password");
                const adminPrivateKeyValue = this.addHexPrefix(adminPrivateKeyInput.value);
                let adminAddress = null;
                if (adminPrivateKeyValue.length === 66) {
                    adminAddress = web3.eth.accounts.privateKeyToAccount(adminPrivateKeyValue).address;
                } else {
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
                        title: "Private key input format is wrong!"
                    });
                    return null
                }

                // Login verification operation
                if (adminPrivateKeyValue === savedAdminPrivateKey &&
                    this.validateEthereumAddress(savedAdminPrivateKey) &&
                    await this.verifyAdministratorStatus(adminAddress) === true) {

                    localStorage.removeItem("adminTemporaryPrivateKey");

                    localStorage.setItem("adminTemporaryPrivateKey", adminPrivateKeyValue);

                    localStorage.removeItem("Role");

                    localStorage.setItem("Role", this.selectedRole);

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
                        icon: "success",
                        title: "Welcome back!"
                    });

                    setTimeout(this.AdminPage, 600)
                } else if (adminPrivateKeyValue.trim() === "") {
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
                        title: "Please enter your private key!"
                    });
                } else if (adminPrivateKeyValue !== savedAdminPrivateKey &&
                    !this.validateEthereumAddress(adminPrivateKeyValue)) {
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
                        title: "Private key is incorrect, please re-enter!"
                    });
                } else if (adminPrivateKeyValue !== savedAdminPrivateKey &&
                    this.validateEthereumAddress(adminPrivateKeyValue) &&
                    await this.verifyAdministratorStatus(adminAddress) === true && remember) {

                    localStorage.removeItem("adminPrivateKey");

                    localStorage.setItem("adminPrivateKey", adminPrivateKeyValue);

                    localStorage.removeItem("adminTemporaryPrivateKey");

                    localStorage.setItem("adminTemporaryPrivateKey", adminPrivateKeyValue);

                    localStorage.removeItem("Role");

                    localStorage.setItem("Role", this.selectedRole);

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
                        icon: "success",
                        title: "Login successfully!"
                    });

                    setTimeout(this.AdminPage, 600)
                } else if (adminPrivateKeyValue !== savedAdminPrivateKey &&
                    this.validateEthereumAddress(adminPrivateKeyValue) &&
                    await this.verifyAdministratorStatus(adminAddress) === true && !remember) {

                    localStorage.removeItem("adminTemporaryPrivateKey");

                    localStorage.setItem("adminTemporaryPrivateKey", adminPrivateKeyValue);

                    localStorage.removeItem("Role");

                    localStorage.setItem("Role", this.selectedRole);

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
                        icon: "success",
                        title: "Login successfully!"
                    });

                    setTimeout(this.AdminPage, 600)
                } else {
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
                        title: "Login failed, only administrators can log in!"
                    });
                }
                this.JudgmentAdminPrivateKey()
            }
        },

        JudgmentPrivateKey() {
            const savedPrivateKey = localStorage.getItem("userPrivateKey");
            const currentPrivateKey = localStorage.getItem("userTemporaryPrivateKey");

            if (currentPrivateKey !== savedPrivateKey && !remember) {
                localStorage.removeItem("PrivateKey");
                localStorage.setItem("PrivateKey", currentPrivateKey);
            } else if (currentPrivateKey === savedPrivateKey) {
                localStorage.removeItem("PrivateKey");
                localStorage.setItem("PrivateKey", savedPrivateKey);
            }
        },

        JudgmentAdminPrivateKey() {
            const SavedPrivateKey = localStorage.getItem("adminPrivateKey");
            const CurrentPrivateKey = localStorage.getItem("adminTemporaryPrivateKey");

            if (CurrentPrivateKey !== SavedPrivateKey && !remember) {
                localStorage.removeItem("AdministratorPrivateKey");
                localStorage.setItem("AdministratorPrivateKey", CurrentPrivateKey);
            } else if (CurrentPrivateKey === SavedPrivateKey) {
                localStorage.removeItem("AdministratorPrivateKey");
                localStorage.setItem("AdministratorPrivateKey", SavedPrivateKey);
            }
        },

        validateEthereumAddress(privateKey) {
            try {
                const account = web3.eth.accounts.privateKeyToAccount(privateKey);
                return isAddress(String(account.address));
            } catch (error) {
                return false;
            }
        },

        addHexPrefix(hexString) {
            if (hexString.startsWith("0x")) {
                return hexString;
            } else {
                return "0x" + hexString;
            }
        },

        UserInterfacePage() {
            this.$router.push('/TestPage2')
        },

        AdminPage() {
            this.$router.push('/TestPage')
        },

        CreateAccountPage() {
            this.$router.push('/CreateAccount')
        },

        async verifyAdministratorStatus(address) {
            return await this.contractInstance.methods.authorized(address).call();
        },

        async createContractInstance(abi, contractAddress) {
            return new Promise((resolve) => {
                const contractInstance = new web3.eth.Contract(abi, contractAddress);
                resolve(contractInstance);
            });
        },
    }
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
h1{
    font-size: 4.5vw; /* 使用vw单位使标题大小随视口宽度变化 */
    white-space: nowrap; /* 防止标题换行 */
    margin-bottom: 10px; /* 添加一些底部间距 */
}

a {
    color: rgb(74, 148, 232);
    transition: color 0.3s ease;
    cursor: pointer;
}

a:hover {
    color: #0056b3;
}

input[type="radio"] {
    display: none;
}
.select-box-container {
    display: flex;
    justify-content: center;
    align-items: center;
    height: 0;
}

.custom-radio {
    display: flex;
    justify-content: center;
    align-items: center;
}

.custom-radio input[type="radio"] {
    width: 20px; /* 设置选择框的宽度 */
    height: 20px; /* 设置选择框的高度 */
    margin-right: 10px; /* 设置选择框之间的间距 */
}

.custom-radio label {
    margin-right: 20px; /* 设置标签之间的间距 */
}
label {
    padding: 10px 15px;
    background-color: #ccc;
    cursor: pointer;
    border: 1px solid #c0bfbf;
    margin-right: 20px;
    margin-bottom: 20px;
    border-radius: 5px;
    outline: none;
    text-align: center;
}

input[type="radio"]:checked + label {
    background-color: rgb(74, 148, 232);
    color: white;
    outline: none;
}

hr {
    width: 340px;
}

.pwd {
    width: 250px;
    height: 25px;
}

.checkbox-group {
    vertical-align: middle;
    margin-top: 3px;
}

#login-btn {
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

#login-btn:active {
    font-size: 21px;
    color: white;
    background-color: rgb(128, 128, 128);
}
@media screen and (min-width: 768px) {
    /* 对于宽度大于等于768px的设备 */
    h1 {
        font-size: 40px; /* 固定标题字体大小 */
    }
}
</style>
