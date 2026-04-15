import { GoogleGenerativeAI } from "@google/generative-ai";
import * as dotenv from "dotenv";

dotenv.config();

const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY!);

async function run() {
  try {
    const fetch = (await import("node-fetch")).default; // If needed
    // The SDK uses native fetch in Node 18+
    
    // There is no listModels in the current SDK easily
    // But we can try to hit the API directly
    const resp = await (await import("node-fetch")).default(`https://generativelanguage.googleapis.com/v1beta/models?key=${process.env.GEMINI_API_KEY}`);
    const data = await resp.json() as any;
    console.log(JSON.stringify(data, null, 2));
  } catch (e) {
    console.error(e);
  }
}

run();
