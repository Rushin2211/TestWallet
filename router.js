import WelcomeToUse from '@/components/WelcomeToUse.vue'
import LogIn from "@/components/LogIn.vue";
import AccountDetail from "@/components/UserInterface.vue";
import AdminInterface from "@/components/AdminInterface.vue";
import NFTStore from "@/components/NFTStore.vue";
import ConnectSuccess from "@/components/ConnectSuccess.vue";
import CreateAccount from "@/components/CreateAccount.vue";
import NewUser from "@/components/NewUser.vue";
import TestPage from "@/components/TestPage.vue"
import ConnectionState from "@/components/ConnectionState.vue";
import AuctionInfo from "@/components/AuctionInfo";
import {createRouter, createWebHashHistory} from "vue-router";

const routes = [
    {
        path: '/',
        name: 'WelcomeToUse',
        component: WelcomeToUse
    },

    {
        path: '/LogIn',
        name: 'LogIn',
        component: LogIn,
    },

    {
        path: '/UserInterface',
        name: 'AccountDetail',
        component: AccountDetail,
    },

    {
        path: '/AdminInterface',
        name: 'AdminInterface',
        component: AdminInterface,
    },
    {
        path: '/NFTStore',
        name: 'NFTStore',
        component: NFTStore,
    },

    {
        path: '/ConnectSuccess',
        name: 'ConnectSuccess',
        component: ConnectSuccess,
    },

    {
        path: '/CreateAccount',
        name: 'CreateAccount',
        component: CreateAccount,
    },

    {
        path: '/NewUser',
        name: 'NewUser',
        component: NewUser,
    },

    {
        path: '/TestPage',
        name: 'TestPage',
        component: TestPage,
    },

    {
        path: '/ConnectionState',
        name: 'ConnectionState',
        component: ConnectionState,
    },
    {
        path: '/AuctionInfo',
        name: 'AuctionInfo',
        component: AuctionInfo,
    }
];

const router = createRouter({
    history: createWebHashHistory(),
    routes,
});

export default router;