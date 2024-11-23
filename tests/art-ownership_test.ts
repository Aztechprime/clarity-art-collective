import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Test registering new artwork",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    
    let block = chain.mineBlock([
      Tx.contractCall('art-ownership', 'register-artwork', [
        types.ascii("Mona Lisa"),
        types.uint(1000), // total shares
        types.uint(100000000) // price per share in microSTX
      ], deployer.address)
    ]);
    
    block.receipts[0].result.expectOk().expectUint(1);
    
    let artworkDetails = chain.mineBlock([
      Tx.contractCall('art-ownership', 'get-artwork-details', [
        types.uint(1)
      ], deployer.address)
    ]);
    
    artworkDetails.receipts[0].result.expectOk().expectSome();
  },
});

Clarinet.test({
  name: "Test share transfer",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const wallet1 = accounts.get('wallet_1')!;
    
    // First register artwork
    let register = chain.mineBlock([
      Tx.contractCall('art-ownership', 'register-artwork', [
        types.ascii("Starry Night"),
        types.uint(1000),
        types.uint(100000000)
      ], deployer.address)
    ]);
    
    // Transfer shares
    let transfer = chain.mineBlock([
      Tx.contractCall('art-ownership', 'transfer-shares', [
        types.uint(1),
        types.principal(wallet1.address),
        types.uint(500)
      ], deployer.address)
    ]);
    
    transfer.receipts[0].result.expectOk().expectBool(true);
    
    // Check new balances
    let deployerShares = chain.mineBlock([
      Tx.contractCall('art-ownership', 'get-shares', [
        types.uint(1),
        types.principal(deployer.address)
      ], deployer.address)
    ]);
    
    let wallet1Shares = chain.mineBlock([
      Tx.contractCall('art-ownership', 'get-shares', [
        types.uint(1),
        types.principal(wallet1.address)
      ], deployer.address)
    ]);
    
    deployerShares.receipts[0].result.expectOk().expectUint(500);
    wallet1Shares.receipts[0].result.expectOk().expectUint(500);
  },
});
