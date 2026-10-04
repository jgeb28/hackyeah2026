#!/usr/bin/env python3
"""Run REAL Laya (original rl_agent_api path) on sample messages and print answers."""
import json
from rl_agent_api import RLAgent

QUESTIONS = {
    "deception": {
        "type": "choice",
        "instructions": "Does this text try to deceive the reader — for example by impersonating "
                        "someone, inventing urgency or a threat, or asking for money, credentials or "
                        "personal data?",
        "criteria": {
            "safe": "the text is not trying to deceive the reader",
            "deceptive": "the text tries to deceive the reader",
        },
    },
    "category": {
        "type": "choice",
        "instructions": "What kind of deceptive text is this?",
        "criteria": {
            "scam": "fraud, phishing, or a request for money or credentials",
            "misinformation": "a false or unverified alarming claim meant to mislead",
            "harassment": "abuse, threats or coercion",
        },
    },
}

SAMPLES = {
    "bank-phishing": "URGENT: This is your bank. Your account has been locked. Verify "
                     "immediately at http://secure-verify-bank.tj49.com and confirm your "
                     "card number and PIN, or your funds will be frozen today.",
    "prize-scam": "Congratulations! You have won a $1000 gift card. Click here to claim now: "
                  "http://bit.ly/claim-now",
    "family-emergency": "Hi sweetie, it's me. I had an accident and I'm using a friend's phone. "
                        "Please send EUR 4800 today or the lawyer will press charges. Don't call, "
                        "I can't talk.",
    "legit-lunch": "Hi, are we still on for lunch tomorrow at 12:30? Let me know.",
    "misinformation": "BREAKING: Scientists confirm that drinking bleach cures every virus. "
                      "Share this before it gets deleted!",
}

def main():
    agent = RLAgent("laya_model", device="cpu")
    for name, msg in SAMPLES.items():
        res = agent.system_one(msg, QUESTIONS)
        a = res["answers"]
        risk = a["risk"]["noul"]
        cat = a["category"]["choice"]
        cat_p = a["category"]["probabilities"].get(cat)
        urg = a["urgency"]["score"]
        print(f"\n=== {name} ===")
        print(f"  risk(noul) = {risk:.3f}   category = {cat} ({cat_p})   urgency = {urg:.2f}")
        print(f"  category probs = {a['category']['probabilities']}")

if __name__ == "__main__":
    main()
