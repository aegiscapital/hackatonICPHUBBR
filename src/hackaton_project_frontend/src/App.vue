<script setup>
import { ref } from 'vue';
import { hackaton_project_backend, canisterId, idlFactory } from 'declarations/hackaton_project_backend/index';
import { Principal } from '@dfinity/principal';
import { AuthClient } from "@dfinity/auth-client";
import { Actor, HttpAgent } from "@dfinity/agent";

// State management
let amounts = ref(['']);
let accounts = ref(['']);
let transferResults = ref([]);
let newPrincipal = ref('');
let allowedPrincipal = ref('');
let loggedPrincipal = ref('');
let error = ref('');
let webapp = null;

// Function to add input fields
function addField() {
  amounts.value.push('');
  accounts.value.push('');
}

// Function to remove a field
function removeField(index) {
  amounts.value.splice(index, 1);
  accounts.value.splice(index, 1);
}

// Handle the bulk transfer
async function handleBulkTransfer(e) {
  e.preventDefault();
  try {
    const transferArgs = {
      amounts: amounts.value.map((amount) => BigInt(amount)),
      toAccounts: accounts.value.map((account) => ({
        owner: Principal.fromText(account),
        subaccount: []
      })),
    };

    const results = await webapp.bulkTransfer(transferArgs);

    console.log(results);

    transferResults.value = results.map(obj => {
      const keys = Object.keys(obj);
      return keys.length > 0 ? keys[0] : null;
    });

    console.log(transferResults.value);

  } catch (err) {
    error.value = "Transfer failed: " + err.message;
  }
}

// Handle transferring privileges
async function handleTransferPrivilege(e) {
  e.preventDefault();
  /* console.log("Current Principal (caller):", Principal.anonymous().toText()); */
  try {
    await webapp.transferPrivilege(Principal.fromText(newPrincipal.value));
    allowedPrincipal.value = await webapp.getAllowedPrincipal();
  } catch (err) {
    error.value = "Privilege transfer failed: " + err.message;
  }
}

async function handleLogin() {
  try {
    const authClient = await AuthClient.create();

    await authClient.login({
      identityProvider: "http://be2us-64aaa-aaaaa-qaabq-cai.localhost:4943/",
      onSuccess: async () => {

        const identity = authClient.getIdentity();
        const principal = identity.getPrincipal().toString();
        const agent = new HttpAgent({ identity });
        agent.fetchRootKey(); // This is needed for local development only

        webapp = Actor.createActor(idlFactory, {
          agent,
          canisterId: canisterId,
        });

        console.log("identity:", identity);
        console.log("principal:", principal);
        loggedPrincipal.value = principal;

        error.value = ""; // Clear any errors
      },
      onError: (err) => {
        error.value = "Login failed: " + err.message;
      }
    });
  } catch (err) {
    error.value = "Login failed: " + err.message;
  }
}

</script>

<template>
  <nav class="top-bar">
    <span v-if="loggedPrincipal">Logged in as: {{ loggedPrincipal }}</span>
    <button class="login-button" @click="handleLogin" :disabled="loggedPrincipal !== ''">
      {{ loggedPrincipal ? 'Logged' : 'Login' }}
    </button>
  </nav>
  <main>
    <h1>ICP Runes Control Panel</h1>
    <form @submit="handleBulkTransfer">
      <h2>Distribute Runes</h2>
      <div v-for="(amount, index) in amounts" :key="index">
        <label>Amount: </label>
        <input v-model="amounts[index]" type="text" required />
        <label>To Account: </label>
        <input v-model="accounts[index]" type="text" required />
        <button type="button" @click="removeField(index)">Remove</button>
      </div>
      <button type="button" @click="addField">Add Another Transfer</button>
      <br /><br />
      <button type="submit">Submit Transfers</button>
    </form>

    <section>
      <span>Distribution Results</span>
      <ul>
        <li v-for="(result, index) in transferResults" :key="index">{{ result }}</li>
      </ul>
    </section>

    <hr />

    <h2>Transfer Privilege</h2>
    <form @submit="handleTransferPrivilege">
      <label>New Principal: </label>
      <input v-model="newPrincipal" type="text" required />
      <button type="submit">Transfer Privilege</button>
    </form>
    <p>Allowed Principal: {{ allowedPrincipal }}</p>

    <p v-if="error">{{ error }}</p>
  </main>
</template>
