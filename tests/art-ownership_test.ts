import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Test registering new artwork with royalties",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    
    let block = chain.mineBlock([
      Tx.contractCall('art-ownership', 'register-artwork', [
        types.ascii("Mona Lisa"),
        types.uint(1000), // total shares
        types.uint(100000000), // price per share in microSTX
        types.uint(10) // 10% royalty
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
  name: "Test share transfer with escrow and royalty payment",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const wallet1 = accounts.get('wallet_1')!;
    
    // First register artwork with 10% royalty
    let register = chain.mineBlock([
      Tx.contractCall('art-ownership', 'register-artwork', [
        types.ascii("Starry Night"),
        types.uint(1000),
        types.uint(100000000),
        types.uint(10)
      ], deployer.address)
    ]);
    
    // Initiate share transfer
    let initiate = chain.mineBlock([
      Tx.contractCall('art-ownership', 'initiate-share-transfer', [
        types.uint(1),
        types.principal(wallet1.address),
        types.uint(500)
      ], deployer.address)
    ]);
    
    initiate.receipts[0].result.expectOk().expectBool(true);
    
    // Complete share transfer with payment
    let complete = chain.mineBlock([
      Tx.contractCall('art-ownership', 'complete-share-transfer', [
        types.uint(1),
        types.principal(deployer.address),
        types.uint(50000000) // 0.5 STX payment
      ], wallet1.address)
    ]);
    
    complete.receipts[0].result.expectOk().expectBool(true);
    
    // Check royalties earned
    let royalties = chain.mineBlock([
      Tx.contractCall('art-ownership', 'get-royalties-earned', [
        types.uint(1),
        types.principal(deployer.address)
      ], deployer.address)
    ]);
    
    royalties.receipts[0].result.expectOk().expectUint(5000000); // 10% of 0.5 STX = 0.05 STX
  },
});
