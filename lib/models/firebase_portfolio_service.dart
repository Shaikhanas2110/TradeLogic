import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

// ─────────────────────────────────────────────────────────────────────────────
// FirebasePortfolioService
//
// Firebase structure:
//   users/{uid}/
//     balance/
//       cash_available    (double)
//       total_invested    (double)
//       total_net_worth   (double)
//     portfolio/
//       {SYMBOL}/
//         symbol          (String)
//         quantity        (int)
//         avg_price       (double)
//         ltp             (double)
// ─────────────────────────────────────────────────────────────────────────────

class FirebasePortfolioService {
  static final _auth = FirebaseAuth.instance;
  static final _db = FirebaseDatabase.instance;

  static String? get _uid => _auth.currentUser?.uid;

  static DatabaseReference? _userRef() {
    final uid = _uid;
    if (uid == null) return null;
    return _db.ref().child("users").child(uid);
  }

  // ── INIT (call once on register) ──────────────────────────────────────────

  static Future<void> initUserAccount({
    double startingBalance = 100000.0,
  }) async {
    final ref = _userRef();
    if (ref == null) return;
    final snap = await ref.child("balance").get();
    if (snap.exists) return; // never overwrite
    await ref.child("balance").set({
      "cash_available": startingBalance,
      "total_invested": 0.0,
      "total_net_worth": startingBalance,
    });
  }

  // ── READ BALANCE (once) ───────────────────────────────────────────────────

  static Future<Map<String, double>> getBalance() async {
    try {
      final ref = _userRef();
      if (ref == null) return _defaultBalance();
      final snap = await ref.child("balance").get();
      if (!snap.exists || snap.value == null) return _defaultBalance();
      final d = Map<String, dynamic>.from(snap.value as Map);
      return {
        "cash_available": (d["cash_available"] ?? 100000.0).toDouble(),
        "total_invested": (d["total_invested"] ?? 0.0).toDouble(),
        "total_net_worth": (d["total_net_worth"] ?? 100000.0).toDouble(),
      };
    } catch (_) {
      return _defaultBalance();
    }
  }

  // ── STREAM BALANCE (real-time) ────────────────────────────────────────────

  static Stream<Map<String, double>> balanceStream() {
    final ref = _userRef();
    if (ref == null) return const Stream.empty();
    return ref.child("balance").onValue.map((e) {
      if (!e.snapshot.exists || e.snapshot.value == null)
        return _defaultBalance();
      final d = Map<String, dynamic>.from(e.snapshot.value as Map);
      return {
        "cash_available": (d["cash_available"] ?? 100000.0).toDouble(),
        "total_invested": (d["total_invested"] ?? 0.0).toDouble(),
        "total_net_worth": (d["total_net_worth"] ?? 100000.0).toDouble(),
      };
    });
  }

  // ── READ PORTFOLIO (once) ─────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getPortfolio() async {
    try {
      final ref = _userRef();
      if (ref == null) return [];
      final snap = await ref.child("portfolio").get();
      if (!snap.exists || snap.value == null) return [];
      final raw = Map<String, dynamic>.from(snap.value as Map);
      return raw.values
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ── STREAM PORTFOLIO (real-time) ──────────────────────────────────────────

  static Stream<List<Map<String, dynamic>>> portfolioStream() {
    final ref = _userRef();
    if (ref == null) return const Stream.empty();
    return ref.child("portfolio").onValue.map((e) {
      if (!e.snapshot.exists || e.snapshot.value == null) return [];
      final raw = Map<String, dynamic>.from(e.snapshot.value as Map);
      return raw.values
          .map((v) => Map<String, dynamic>.from(v as Map))
          .toList();
    });
  }

  // ── BUY ───────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> buyShares({
    required String symbol,
    required int quantity,
    required double price,
  }) async {
    final ref = _userRef();
    if (ref == null) return {"success": false, "error": "Not logged in"};

    final totalCost = quantity * price;

    // Read current state
    final balSnap = await ref.child("balance").get();
    if (!balSnap.exists)
      return {"success": false, "error": "Balance not found"};
    final bal = Map<String, dynamic>.from(balSnap.value as Map);
    final double cash = (bal["cash_available"] ?? 0.0).toDouble();

    if (totalCost > cash) {
      return {
        "success": false,
        "error":
            "Insufficient balance. Need ₹${totalCost.toStringAsFixed(2)}, available ₹${cash.toStringAsFixed(2)}",
      };
    }

    // Read existing position if any
    final posSnap = await ref.child("portfolio").child(symbol).get();
    int newQty;
    double newAvg;

    if (posSnap.exists && posSnap.value != null) {
      final pos = Map<String, dynamic>.from(posSnap.value as Map);
      final oldQty = (pos["quantity"] ?? 0) as int;
      final oldAvg = (pos["avg_price"] ?? 0.0).toDouble();
      newQty = oldQty + quantity;
      newAvg = ((oldQty * oldAvg) + (quantity * price)) / newQty;
    } else {
      newQty = quantity;
      newAvg = price;
    }

    final double newCash = cash - totalCost;
    final double oldInvested = (bal["total_invested"] ?? 0.0).toDouble();
    final double newInvested = oldInvested + totalCost;

    // Write position
    await ref.child("portfolio").child(symbol).set({
      "symbol": symbol,
      "quantity": newQty,
      "avg_price": double.parse(newAvg.toStringAsFixed(2)),
      "ltp": price,
    });

    // Recalculate net worth
    final double netWorth = await _calcNetWorth(ref, newCash);

    // Write balance
    await ref.child("balance").update({
      "cash_available": double.parse(newCash.toStringAsFixed(2)),
      "total_invested": double.parse(newInvested.toStringAsFixed(2)),
      "total_net_worth": double.parse(netWorth.toStringAsFixed(2)),
    });

    

    debugPrint("BUY $quantity $symbol @ ₹$price | Cash left: ₹$newCash");
    return {
      "success": true,
      "msg":
          "Bought $quantity shares of $symbol @ ₹${price.toStringAsFixed(2)}",
      "cash_available": newCash,
    };
  }

  // ── SELL ──────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> sellShares({
    required String symbol,
    required int quantity,
    required double sellPrice,
  }) async {
    final ref = _userRef();
    if (ref == null) return {"success": false, "error": "Not logged in"};

    // Read position
    final posSnap = await ref.child("portfolio").child(symbol).get();
    if (!posSnap.exists || posSnap.value == null) {
      return {"success": false, "error": "No position found for $symbol"};
    }

    final pos = Map<String, dynamic>.from(posSnap.value as Map);
    final int held = (pos["quantity"] ?? 0) as int;
    final double avgPrice = (pos["avg_price"] ?? 0.0).toDouble();

    if (quantity > held) {
      return {
        "success": false,
        "error": "Cannot sell $quantity — only holding $held",
      };
    }

    // Read balance
    final balSnap = await ref.child("balance").get();
    final bal = Map<String, dynamic>.from(balSnap.value as Map);
    final double cash = (bal["cash_available"] ?? 0.0).toDouble();
    final double invested = (bal["total_invested"] ?? 0.0).toDouble();

    final double proceeds = quantity * sellPrice;
    final double pnl = (sellPrice - avgPrice) * quantity;
    final double newCash = cash + proceeds;
    final double costBasis = avgPrice * quantity;
    final double newInvested = (invested - costBasis).clamp(
      0.0,
      double.infinity,
    );

    // Update or remove position
    if (quantity == held) {
      await ref.child("portfolio").child(symbol).remove();
    } else {
      await ref.child("portfolio").child(symbol).update({
        "quantity": held - quantity,
        "ltp": sellPrice,
      });
    }

    // Recalculate net worth
    final double netWorth = await _calcNetWorth(ref, newCash);

    // Write balance
    await ref.child("balance").update({
      "cash_available": double.parse(newCash.toStringAsFixed(2)),
      "total_invested": double.parse(newInvested.toStringAsFixed(2)),
      "total_net_worth": double.parse(netWorth.toStringAsFixed(2)),
    });

    debugPrint(
      "SELL $quantity $symbol @ ₹$sellPrice | P&L: ₹${pnl.toStringAsFixed(2)}",
    );
    return {
      "success": true,
      "msg":
          "Sold $quantity shares of $symbol @ ₹${sellPrice.toStringAsFixed(2)}",
      "pnl": pnl,
      "cash_available": newCash,
    };
  }

  // ── UPDATE LTP (call after fetching live price) ───────────────────────────

  static Future<void> updateLTP(String symbol, double ltp) async {
    final ref = _userRef();
    if (ref == null) return;
    final posSnap = await ref.child("portfolio").child(symbol).get();
    if (!posSnap.exists) return;
    await ref.child("portfolio").child(symbol).update({"ltp": ltp});

    // Recalculate and update net worth
    final balSnap = await ref.child("balance").get();
    if (!balSnap.exists) return;
    final bal = Map<String, dynamic>.from(balSnap.value as Map);
    final cash = (bal["cash_available"] ?? 0.0).toDouble();
    final netWorth = await _calcNetWorth(ref, cash);
    await ref.child("balance").update({
      "total_net_worth": double.parse(netWorth.toStringAsFixed(2)),
    });
  }

  // ── PRIVATE HELPERS ───────────────────────────────────────────────────────

  /// Sum cash + all holdings at their current LTP
  static Future<double> _calcNetWorth(
    DatabaseReference ref,
    double cash,
  ) async {
    try {
      final snap = await ref.child("portfolio").get();
      if (!snap.exists || snap.value == null) return cash;
      final raw = Map<String, dynamic>.from(snap.value as Map);
      double holdingsValue = 0.0;
      for (final pos in raw.values) {
        final p = Map<String, dynamic>.from(pos as Map);
        final qty = (p["quantity"] ?? 0).toDouble();
        final ltp = (p["ltp"] ?? p["avg_price"] ?? 0.0).toDouble();
        holdingsValue += qty * ltp;
      }
      return cash + holdingsValue;
    } catch (_) {
      return cash;
    }
  }

  static Map<String, double> _defaultBalance() => {
    "cash_available": 100000.0,
    "total_invested": 0.0,
    "total_net_worth": 100000.0,
  };
}
