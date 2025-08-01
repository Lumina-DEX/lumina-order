"use server";
import { getConfig } from "./config.js";
import { publicKeyToU256 } from "./public-key.js";
import { Transaction } from "@mysten/sui/transactions";
import { getKey, getUserKey } from "./key.js";
import { executeOperationTx } from "./operaton.js";
import { fetchDexAccount } from "./fetch.js";
import { ActionRequest, MinaSignature, Operation } from "./types.js";
import { prepareSignPayload } from "./sign.js";
import { wrapMinaSignature } from "./wrap.js";
import {
  TransactionType,
  ActionAskRequest,
  ActionBidRequest,
  ActionTransferRequest,
} from "./types.js";
import { LastTransactionData } from "./types.js";
import { convertMinaSignatureFromBase58 } from "./base58/signature.js";

export interface OrderPayload {
  poolPublicKey: string;
  user: string;
  payload: bigint[];
  baseTokenAmount: bigint;
  quoteTokenAmount?: bigint;
  price?: bigint;
  receiverPublicKey?: string;
  nonce: bigint;
  operation: Operation;
}

export async function prepareOrderPayload(params: {
  user: string;
  amount: number;
  price?: number;
  recipient?: string;
  type: TransactionType;
  currency: "WETH" | "WUSD";
}): Promise<OrderPayload> {
  console.log("prepareOrderPayload", params);
  if (
    params.type !== "buy" &&
    params.type !== "sell" &&
    params.type !== "transfer"
  ) {
    throw new Error("Invalid transaction type");
  }
  const { user, type, currency } = params;
  const config = await getConfig();
  const u256 = publicKeyToU256(user);
  const packageID = config.dex_package;
  const dexID = config.dex_object;
  const poolPublicKey = config.mina_contract;

  if (!poolPublicKey) {
    throw new Error("POOL PUBLIC KEY is not set");
  }

  if (!packageID) {
    throw new Error("PACKAGE_ID is not set");
  }

  if (!dexID) {
    throw new Error("DEX_ID is not set");
  }

  const userAccount = await fetchDexAccount({ addressU256: u256 });
  if (!userAccount) {
    throw new Error("Cannot fetch accounts");
  }
  let nonce = userAccount.nonce;
  if (type === "buy" || type === "sell" || type === "transfer") {
    if (params.amount === undefined) {
      throw new Error("Amount is not set");
    }
  }
  let amount: bigint | undefined =
    BigInt(parseInt(((params.amount ?? 0) * 1_000_000).toString())) * 1000n;
  let price: bigint | undefined = undefined;
  let recipient: string | undefined = undefined;

  if (type === "buy" || type === "sell") {
    if (params.price === undefined) {
      throw new Error("Price is not set");
    }
    price = BigInt(parseInt((params.price * 1_000_000).toString())) * 1000n;
  }
  if (type === "transfer") {
    if (params.recipient === undefined) {
      throw new Error("Recipient is not set");
    }
    if (amount === undefined || amount === 0n) {
      throw new Error("Transfer amount should be greater than 0");
    }
    recipient = params.recipient;
  }

  let operation =
    params.type === "buy"
      ? Operation.BID
      : params.type === "sell"
      ? Operation.ASK
      : Operation.TRANSFER;

  const baseTokenAmount = currency === "WETH" ? amount : 0n;
  const quoteTokenAmount =
    currency === "WUSD" && type === "transfer"
      ? amount
      : type === "transfer"
      ? 0n
      : undefined;
  const priceBigInt = type === "buy" || type === "sell" ? price : undefined;
  const receiverPublicKey = type === "transfer" ? recipient : undefined;

  const payload = prepareSignPayload({
    poolPublicKey: poolPublicKey,
    operation,
    nonce,
    baseTokenAmount,
    quoteTokenAmount,
    price: priceBigInt,
    receiverPublicKey,
  });
  return {
    poolPublicKey,
    user,
    payload,
    baseTokenAmount,
    quoteTokenAmount,
    price: priceBigInt,
    receiverPublicKey,
    nonce,
    operation,
  };
}

export async function orderWithPayload(params: {
  payload: OrderPayload;
  signature: string;
  key?: string;
}): Promise<Partial<LastTransactionData>> {
  const { payload, signature, key } = params;
  const actionRequest = await convertOrderPayloadToActionRequest({
    payload,
    signature,
  });
  return order({ actionRequest, key });
}

export async function convertOrderPayloadToActionRequest(params: {
  payload: OrderPayload;
  signature: string;
}): Promise<ActionRequest> {
  console.log("convertOrderPayloadToActionRequest", params);
  const { payload, signature } = params;
  const {
    poolPublicKey,
    user,
    baseTokenAmount,
    quoteTokenAmount,
    price,
    receiverPublicKey,
    nonce,
    operation,
  } = payload;
  if (
    operation !== Operation.BID &&
    operation !== Operation.ASK &&
    operation !== Operation.TRANSFER
  ) {
    throw new Error("Invalid operation");
  }
  let actionRequest: ActionRequest;

  // Parse signature string into MinaSignature object
  const minaSignature: MinaSignature =
    convertMinaSignatureFromBase58(signature);

  switch (operation) {
    case Operation.BID:
      actionRequest = {
        userPublicKey: user,
        nonce,
        baseTokenAmount,
        price,
        isSome: true,
        userSignature: minaSignature,
        poolPublicKey,
        operation: Operation.BID,
      } as ActionBidRequest;
      break;
    case Operation.ASK:
      actionRequest = {
        userPublicKey: user,
        nonce,
        baseTokenAmount,
        price,
        isSome: true,
        userSignature: minaSignature,
        poolPublicKey,
        operation: Operation.ASK,
      } as ActionAskRequest;
      break;
    case Operation.TRANSFER:
      if (!receiverPublicKey) {
        throw new Error("Receiver public key is required for transfer");
      }
      actionRequest = {
        senderPublicKey: user,
        senderNonce: nonce,
        receiverPublicKey,
        receiverNonce: 0n, // Default value, might need to be fetched
        baseTokenAmount,
        quoteTokenAmount,
        isSome: true,
        senderSignature: minaSignature,
        poolPublicKey,
        operation: Operation.TRANSFER,
      } as ActionTransferRequest;
      break;
    default:
      throw new Error(`Unsupported operation: ${operation}`);
  }
  if (!actionRequest) {
    throw new Error("Invalid action request");
  }
  return actionRequest;
}

export async function order(params: {
  actionRequest: ActionRequest;
  key?: string;
}): Promise<Partial<LastTransactionData>> {
  console.log("order", params);
  const start = Date.now();
  const { actionRequest } = params;
  const { operation } = actionRequest;
  if (
    operation !== Operation.BID &&
    operation !== Operation.ASK &&
    operation !== Operation.TRANSFER
  ) {
    throw new Error("Invalid operation");
  }
  const user =
    operation === Operation.BID
      ? actionRequest.userPublicKey
      : operation === Operation.ASK
      ? actionRequest.userPublicKey
      : actionRequest.senderPublicKey;

  const userNonce =
    operation === Operation.BID
      ? actionRequest.nonce
      : operation === Operation.ASK
      ? actionRequest.nonce
      : actionRequest.senderNonce;

  const baseTokenAmount =
    operation === Operation.BID
      ? actionRequest.baseTokenAmount
      : operation === Operation.ASK
      ? actionRequest.baseTokenAmount
      : actionRequest.baseTokenAmount;

  const signature =
    operation === Operation.BID
      ? actionRequest.userSignature
      : operation === Operation.ASK
      ? actionRequest.userSignature
      : actionRequest.senderSignature;

  const receiverPublicKey =
    operation === Operation.TRANSFER
      ? actionRequest.receiverPublicKey
      : undefined;

  const quoteTokenAmount =
    operation === Operation.TRANSFER
      ? actionRequest.quoteTokenAmount
      : undefined;

  const price =
    operation === Operation.BID
      ? actionRequest.price
      : operation === Operation.ASK
      ? actionRequest.price
      : undefined;
  console.log("order", {
    operation,
    user,
    userNonce,
    baseTokenAmount,
    price,
  });
  let keyPromise: Promise<string> | undefined = undefined;
  if (params.key) {
    keyPromise = undefined;
  } else {
    keyPromise = getUserKey();
  }
  const u256 = publicKeyToU256(user);
  const userAccountPromise = fetchDexAccount({ addressU256: u256 });
  const config = await getConfig();
  const poolPublicKey = config.mina_contract;

  if (!poolPublicKey) {
    throw new Error("POOL PUBLIC KEY is not set");
  }

  const userAccount = await userAccountPromise;
  if (!userAccount) {
    throw new Error("Cannot fetch accounts");
  }
  console.log("order userAccount", userAccount);
  const packageID = config.dex_package;
  const dexID = config.dex_object;
  if (!packageID) {
    throw new Error("PACKAGE_ID is not set");
  }

  if (!dexID) {
    throw new Error("DEX_ID is not set");
  }

  let nonce = userAccount.nonce;
  if (nonce !== userNonce) {
    console.error("nonce mismatch", { nonce, userNonce });
    throw new Error("Nonce mismatch");
  }

  const tx = new Transaction();

  const { minaSignature, suiSignature } = await wrapMinaSignature({
    minaSignature: signature,
    minaPublicKey: user,
    poolPublicKey: poolPublicKey,
    operation,
    nonce,
    baseTokenAmount,
    quoteTokenAmount,
    price,
    receiverPublicKey,
  });

  if (operation === Operation.BID) {
    if (price === undefined) {
      throw new Error("Price is not set");
    }

    if (baseTokenAmount === undefined) {
      throw new Error("Base token amount is not set");
    }

    const bidArguments = [
      tx.object(dexID),
      tx.pure.u256(u256),
      tx.pure.u64(baseTokenAmount),
      tx.pure.u64(price),
      tx.pure.u256(minaSignature.r),
      tx.pure.u256(minaSignature.s),
      tx.pure.vector("u8", suiSignature),
    ];

    tx.moveCall({
      package: packageID,
      module: "transactions",
      function: "bid",
      arguments: bidArguments,
    });
  }

  if (operation === Operation.ASK) {
    if (price === undefined) {
      throw new Error("Price is not set");
    }

    if (baseTokenAmount === undefined) {
      throw new Error("Base token amount is not set");
    }

    const askArguments = [
      tx.object(dexID),
      tx.pure.u256(u256),
      tx.pure.u64(baseTokenAmount),
      tx.pure.u64(price),
      tx.pure.u256(minaSignature.r),
      tx.pure.u256(minaSignature.s),
      tx.pure.vector("u8", suiSignature),
    ];

    tx.moveCall({
      package: packageID,
      module: "transactions",
      function: "ask",
      arguments: askArguments,
    });
  }

  if (operation === Operation.TRANSFER) {
    if (quoteTokenAmount === undefined) {
      throw new Error("Quote token amount is not set");
    }
    if (!receiverPublicKey) {
      throw new Error("Receiver public key is not set");
    }
    const transferArguments = [
      tx.object(dexID),
      tx.pure.u256(u256),
      tx.pure.u256(publicKeyToU256(receiverPublicKey)),
      tx.pure.u64(baseTokenAmount),
      tx.pure.u64(quoteTokenAmount),
      tx.pure.u256(minaSignature.r),
      tx.pure.u256(minaSignature.s),
      tx.pure.vector("u8", suiSignature),
    ];

    tx.moveCall({
      package: packageID,
      module: "transactions",
      function: "transfer",
      arguments: transferArguments,
    });
  }

  const key = params.key ?? (await keyPromise);
  const { address, keypair } = await getKey({
    secretKey: key,
    name: "user",
  });

  tx.setSender(address);
  tx.setGasBudget(10_000_000);

  // const signedTx = await tx.sign({
  //   signer: keypair,
  //   client: suiClient,
  // });

  const end = Date.now();
  const prepareTime = end - start;
  const result = await executeOperationTx({
    operation: operation,
    tx,
    keyPair: keypair,
  });
  console.log("tx result:", result);

  return { ...result, prepareTime };
}
