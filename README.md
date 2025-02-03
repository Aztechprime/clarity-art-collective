# Art Collective Ownership Contract

A blockchain-based solution for managing collective art ownership rights. This contract enables:

- Artists to register their artwork and divide ownership into shares
- Transfer of ownership shares between users with automatic royalty payments
- Tracking of artwork details and ownership distribution
- Verification of share ownership
- Automatic royalty distribution to artists on secondary sales

The system provides a transparent and decentralized way to manage fractional ownership of artwork, enabling broader participation in art investment and collective ownership.

## Royalty System

The contract includes an automated royalty distribution system that:
- Allows artists to set royalty percentages when registering artwork
- Automatically calculates and transfers royalty payments during share transfers
- Tracks accumulated royalty payments for each artwork and artist
- Ensures fair compensation for artists in the secondary market

Royalty payments are processed automatically during share transfers, with the specified percentage of the sale price being sent directly to the original artist.

## Secure Share Transfer

The contract now implements a two-step escrow system for share transfers:
1. Seller initiates the transfer by placing shares in escrow
2. Buyer completes the transfer by paying the agreed amount

This ensures:
- Safe atomic transactions between parties
- Prevention of double-spending
- Protection against failed transfers
- Automatic royalty distribution on successful completion
