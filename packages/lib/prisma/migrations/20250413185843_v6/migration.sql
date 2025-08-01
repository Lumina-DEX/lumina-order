-- AlterTable
ALTER TABLE "ActionRequest" ALTER COLUMN "baseBalance" SET DATA TYPE DECIMAL(65,30),
ALTER COLUMN "quoteBalance" SET DATA TYPE DECIMAL(65,30),
ALTER COLUMN "baseTokenAmount" SET DATA TYPE DECIMAL(65,30),
ALTER COLUMN "price" SET DATA TYPE DECIMAL(65,30),
ALTER COLUMN "nonce" SET DATA TYPE DECIMAL(65,30),
ALTER COLUMN "quoteTokenAmount" SET DATA TYPE DECIMAL(65,30),
ALTER COLUMN "buyerNonce" SET DATA TYPE DECIMAL(65,30),
ALTER COLUMN "sellerNonce" SET DATA TYPE DECIMAL(65,30),
ALTER COLUMN "senderNonce" SET DATA TYPE DECIMAL(65,30),
ALTER COLUMN "receiverNonce" SET DATA TYPE DECIMAL(65,30),
ALTER COLUMN "senderSignatureR" SET DATA TYPE DECIMAL(65,30),
ALTER COLUMN "senderSignatureS" SET DATA TYPE DECIMAL(65,30),
ALTER COLUMN "userSignatureR" SET DATA TYPE DECIMAL(65,30),
ALTER COLUMN "userSignatureS" SET DATA TYPE DECIMAL(65,30),
ALTER COLUMN "sequence" SET DATA TYPE DECIMAL(65,30);

-- AlterTable
ALTER TABLE "State" ALTER COLUMN "baseTokenAmount" SET DATA TYPE DECIMAL(65,30),
ALTER COLUMN "baseTokenStakedAmount" SET DATA TYPE DECIMAL(65,30),
ALTER COLUMN "baseTokenBorrowedAmount" SET DATA TYPE DECIMAL(65,30),
ALTER COLUMN "quoteTokenAmount" SET DATA TYPE DECIMAL(65,30),
ALTER COLUMN "quoteTokenStakedAmount" SET DATA TYPE DECIMAL(65,30),
ALTER COLUMN "quoteTokenBorrowedAmount" SET DATA TYPE DECIMAL(65,30),
ALTER COLUMN "bidAmount" SET DATA TYPE DECIMAL(65,30),
ALTER COLUMN "bidPrice" SET DATA TYPE DECIMAL(65,30),
ALTER COLUMN "askAmount" SET DATA TYPE DECIMAL(65,30),
ALTER COLUMN "askPrice" SET DATA TYPE DECIMAL(65,30),
ALTER COLUMN "nonce" SET DATA TYPE DECIMAL(65,30);
