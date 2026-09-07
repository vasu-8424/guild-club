// Supabase Edge Function: daily-login-bonus
// Grants +2 daily login bonus automatically once per calendar day per user

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

interface LoginBonusResult {
  claimed_today: boolean;
  bonus_granted: number;
  coin_balance: number;
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

    // 1. Authenticate User JWT Token from Authorization Header
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(
        JSON.stringify({ claimed_today: false, bonus_granted: 0, coin_balance: 0, message: "Missing Authorization header" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const token = authHeader.replace("Bearer ", "");
    const { data: { user }, error: userError } = await supabaseClient.auth.getUser(token);

    if (userError || !user) {
      return new Response(
        JSON.stringify({ claimed_today: false, bonus_granted: 0, coin_balance: 0, message: "Unauthorized user session" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const userId = user.id;
    const today = new Date().toISOString().split("T")[0]; // YYYY-MM-DD format

    // 2. Query daily_activity Table for Today's Date
    const { data: activityData } = await supabaseClient
      .from("daily_activity")
      .select("login_bonus_claimed_today, spun_today")
      .eq("user_id", userId)
      .eq("activity_date", today)
      .maybeSingle();

    // 3. Fetch Current Wallet Balance
    const { data: existingWallet } = await supabaseClient
      .from("wallets")
      .select("coin_balance")
      .eq("user_id", userId)
      .maybeSingle();

    let currentBalance = existingWallet?.coin_balance ?? 0;

    // If already claimed today: return current balance silently without error
    if (activityData && activityData.login_bonus_claimed_today === true) {
      const payload: LoginBonusResult = {
        claimed_today: true,
        bonus_granted: 0,
        coin_balance: currentBalance,
        message: "Daily login bonus already claimed today.",
      };
      return new Response(JSON.stringify(payload), {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // 4. Claim +2 Daily Login Bonus
    const bonusCoins = 2;

    // Insert row into reward_transactions (Trigger will automatically update wallets.coin_balance)
    const { error: txError } = await supabaseClient.from("reward_transactions").insert({
      user_id: userId,
      type: "daily_login_bonus",
      amount: bonusCoins,
      metadata: { source: "automatic_daily_login" },
    });

    if (txError) {
      throw new Error(`Failed to record daily login transaction: ${txError.message}`);
    }

    // Upsert daily_activity table
    const { error: dailyError } = await supabaseClient.from("daily_activity").upsert({
      user_id: userId,
      activity_date: today,
      login_bonus_claimed_today: true,
      spun_today: activityData?.spun_today ?? false,
    });

    if (dailyError) {
      throw new Error(`Failed to update daily activity status: ${dailyError.message}`);
    }

    // 5. Query Fresh Wallet Balance
    const { data: updatedWallet } = await supabaseClient
      .from("wallets")
      .select("coin_balance")
      .eq("user_id", userId)
      .single();

    const newBalance = updatedWallet?.coin_balance ?? (currentBalance + bonusCoins);

    const payload: LoginBonusResult = {
      claimed_today: false,
      bonus_granted: bonusCoins,
      coin_balance: newBalance,
      message: "Daily login bonus claimed! +2 Guild Coins",
    };

    return new Response(JSON.stringify(payload), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (err: any) {
    return new Response(
      JSON.stringify({ claimed_today: false, bonus_granted: 0, coin_balance: 0, message: err.message ?? "Server error" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
