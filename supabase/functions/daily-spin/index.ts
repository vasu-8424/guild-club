// Supabase Edge Function: daily-spin
// Secure server-side logic enforcing one spin per day and weighted prize calculation

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

interface SpinResult {
  success: boolean;
  already_spun: boolean;
  won_amount?: number;
  segment_index?: number;
  new_balance?: number;
  message: string;
}

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    const supabaseClient = createClient(supabaseUrl, supabaseServiceKey);

    // 1. Authenticate User JWT from Auth Header
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(
        JSON.stringify({ success: false, already_spun: false, message: "Missing Authorization header" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const token = authHeader.replace("Bearer ", "");
    const { data: { user }, error: userError } = await supabaseClient.auth.getUser(token);

    if (userError || !user) {
      return new Response(
        JSON.stringify({ success: false, already_spun: false, message: "Unauthorized user session" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const userId = user.id;
    const today = new Date().toISOString().split("T")[0]; // YYYY-MM-DD format

    // 2. Check daily_activity Table for Today's Date
    const { data: activityData } = await supabaseClient
      .from("daily_activity")
      .select("spun_today")
      .eq("user_id", userId)
      .eq("activity_date", today)
      .single();

    if (activityData && activityData.spun_today === true) {
      return new Response(
        JSON.stringify({
          success: false,
          already_spun: true,
          message: "You've already spun today! Come back tomorrow.",
        }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 3. Server-Determined Wheel Outcome (Weighted Selection)
    // Segments matching UI order:
    // 0: +20, 1: +50, 2: +80, 3: +30, 4: +60, 5: +40
    const rewards = [
      { coins: 20, index: 0, weight: 35 },
      { coins: 50, index: 1, weight: 15 },
      { coins: 80, index: 2, weight: 5 },
      { coins: 30, index: 3, weight: 25 },
      { coins: 60, index: 4, weight: 10 },
      { coins: 40, index: 5, weight: 10 },
    ];

    const totalWeight = rewards.reduce((acc, r) => acc + r.weight, 0);
    let randomVal = Math.floor(Math.random() * totalWeight);
    let chosenReward = rewards[0];

    for (const reward of rewards) {
      if (randomVal < reward.weight) {
        chosenReward = reward;
        break;
      }
      randomVal -= reward.weight;
    }

    // 4. Insert Ledger Row into reward_transactions
    // Note: Database Trigger `trigger_update_wallet_balance` will automatically update wallets.coin_balance!
    const { error: txError } = await supabaseClient.from("reward_transactions").insert({
      user_id: userId,
      type: "daily_spin",
      amount: chosenReward.coins,
      metadata: { segment_index: chosenReward.index, won_amount: chosenReward.coins },
    });

    if (txError) {
      throw new Error(`Failed to record transaction: ${txError.message}`);
    }

    // 5. Update daily_activity Table
    const { error: dailyErr } = await supabaseClient.from("daily_activity").upsert({
      user_id: userId,
      activity_date: today,
      spun_today: true,
      login_bonus_claimed_today: false,
    });

    if (dailyErr) {
      throw new Error(`Failed to record daily activity: ${dailyErr.message}`);
    }

    // 6. Fetch New Total Balance from wallets Table
    const { data: walletData } = await supabaseClient
      .from("wallets")
      .select("coin_balance")
      .eq("user_id", userId)
      .single();

    const newBalance = walletData?.coin_balance ?? 0;

    const responsePayload: SpinResult = {
      success: true,
      already_spun: false,
      won_amount: chosenReward.coins,
      segment_index: chosenReward.index,
      new_balance: newBalance,
      message: `Congratulations! You won +${chosenReward.coins} ToyCoins!`,
    };

    return new Response(JSON.stringify(responsePayload), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (err: any) {
    return new Response(
      JSON.stringify({ success: false, already_spun: false, message: err.message ?? "Server error during spin" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
