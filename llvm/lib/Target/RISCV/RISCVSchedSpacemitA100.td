//=- RISCVSchedSpacemitA100.td - Spacemit A100 Scheduling Defs -*- tablegen -*-=//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
// Helpers
// Latency helper classes

// Used for: arithmetic (add/sub/min/max), saturating/averaging, FP add/sub/min/max
class Get45816Latency<string mx> {
  int c = GetLMULValue<[/*MF8=*/4, /*MF4=*/4, /*MF2=*/4, /*M1=*/4, /*M2=*/5, /*M4=*/8, /*M8=*/16], mx>.c;
}

// Returns MF8->1, MF4->2, MF2->4, M1->8, M2->16, M4->32, M8->64
class ConstOneUntilMF8ThenDouble<string mx> {
  int c = ConstValueUntilLMULThenDouble<"MF8", 1, mx>.c;
}

//===----------------------------------------------------------------------===//

class SMTA100IsWorstCaseMX<string mx, list<string> MxList> {
  string LLMUL = LargestLMUL<MxList>.r;
  bit c = !eq(mx, LLMUL);
}

class SMTA100IsWorstCaseMXSEW<string mx, int sew, list<string> MxList, bit isF = 0> {
  string LLMUL = LargestLMUL<MxList>.r;
  int SSEW = SmallestSEW<mx, isF>.r;
  bit c = !and(!eq(mx, LLMUL), !eq(sew, SSEW));
}

defvar SMTA100VLEN = 1024;
defvar SMTA100DLEN = !div(SMTA100VLEN, 2);

class SMTA100GetLMulCycles<string mx> {
  int c = !cond(
    !eq(mx, "M1") : 1,
    !eq(mx, "M2") : 2,
    !eq(mx, "M4") : 4,
    !eq(mx, "M8") : 8,
    !eq(mx, "MF2") : 1,
    !eq(mx, "MF4") : 1,
    !eq(mx, "MF8") : 1
  );
}

class SMTA100GetVLMAX<string mx, int sew> {
  defvar LMUL = SMTA100GetLMulCycles<mx>.c;
  int val = !cond(
    !eq(mx, "MF2") : !div(!div(SMTA100VLEN, 2), sew),
    !eq(mx, "MF4") : !div(!div(SMTA100VLEN, 4), sew),
    !eq(mx, "MF8") : !div(!div(SMTA100VLEN, 8), sew),
    true: !div(!mul(SMTA100VLEN, LMUL), sew)
  );
}

// Latency for segmented loads and stores are calculated as vl * nf.
class SMTA100SegmentedLdStCycles<string mx, int sew, int nf> {
  int c = !mul(SMTA100GetVLMAX<mx, sew>.val, nf);
}

def SpacemitA100Model : SchedMachineModel {
  let IssueWidth        = 2; // dual-issue
  let MicroOpBufferSize = 1; // in-order
  let LoadLatency       = 3; // worse case: >= 3
  let MispredictPenalty = 9; // nine-stage

  let CompleteModel = 0;

  let UnsupportedFeatures = [HasStdExtZknd, HasStdExtZkne, HasStdExtZknh,
                             HasStdExtZksed, HasStdExtZksh, HasStdExtZkr,
                             HasVendorXSMTVDotII];
}

let SchedModel = SpacemitA100Model in {

//===----------------------------------------------------------------------===//
// Define processor resources for Spacemit-A100

let BufferSize = 0 in {
  // The LSU supports dual issue for scalar store/load instructions
  def SMTA100_LS : ProcResource<2>;

  // An IEU can decode and issue two instructions at the same time
  def SMTA100_IEUA : ProcResource<1>;
  def SMTA100_IEUB : ProcResource<1>;
  def SMTA100_IEU : ProcResGroup<[SMTA100_IEUA, SMTA100_IEUB]>;

  def SMTA100_FP : ProcResource<1>;

}

// Vector pipeline
def SMTA100_VEU0 : ProcResource<1>;
def SMTA100_VEU1 : ProcResource<1>;

def SMTA100_VIEU : ProcResGroup<[SMTA100_VEU0, SMTA100_VEU1]>;
def SMTA100_VFPU : ProcResGroup<[SMTA100_VEU0, SMTA100_VEU1]>;
defvar SMTA100_VLSU = SMTA100_VEU0;

//===----------------------------------------------------------------------===//

// Branching
def : WriteRes<WriteJmp, [SMTA100_IEUA]>;
def : WriteRes<WriteJal, [SMTA100_IEUA]>;
def : WriteRes<WriteJalr, [SMTA100_IEUA]>;

// Integer arithmetic and logic
// Latency of ALU instructions is 1, but add.uw is 2
def : WriteRes<WriteIALU32, [SMTA100_IEU]>;
def : WriteRes<WriteIALU, [SMTA100_IEU]>;
def : WriteRes<WriteShiftImm32, [SMTA100_IEU]>;
def : WriteRes<WriteShiftImm, [SMTA100_IEU]>;
def : WriteRes<WriteShiftReg32, [SMTA100_IEU]>;
def : WriteRes<WriteShiftReg, [SMTA100_IEU]>;

// Integer multiplication
def : WriteRes<WriteIMul32, [SMTA100_IEU]>  { let Latency = 3; }

// The latency of mul is 5, while in mulh, mulhsu, mulhu is 6
// Worst case latency is used
def : WriteRes<WriteIMul, [SMTA100_IEU]>  { let Latency = 6; }

// Integer division/remainder
// TODO: Latency set based on C908 datasheet and hasn't been
// confirmed experimentally.
let Latency = 12, ReleaseAtCycles = [12] in {
  def : WriteRes<WriteIDiv32, [SMTA100_IEUA]>;
  def : WriteRes<WriteIRem32, [SMTA100_IEUA]>;
}
let Latency = 20, ReleaseAtCycles = [20] in {
  def : WriteRes<WriteIDiv, [SMTA100_IEUA]>;
  def : WriteRes<WriteIRem, [SMTA100_IEUA]>;
}

// Bitmanip
def : WriteRes<WriteRotateImm, [SMTA100_IEU]>;
def : WriteRes<WriteRotateImm32, [SMTA100_IEU]>;
def : WriteRes<WriteRotateReg, [SMTA100_IEU]>;
def : WriteRes<WriteRotateReg32, [SMTA100_IEU]>;

def : WriteRes<WriteCLZ, [SMTA100_IEU]>;
def : WriteRes<WriteCLZ32, [SMTA100_IEU]>;
def : WriteRes<WriteCTZ, [SMTA100_IEU]>;
def : WriteRes<WriteCTZ32, [SMTA100_IEU]>;

let Latency = 2 in {
  def : WriteRes<WriteCPOP, [SMTA100_IEU]>;
  def : WriteRes<WriteCPOP32, [SMTA100_IEU]>;
}

def : WriteRes<WriteORCB, [SMTA100_IEU]>;
def : WriteRes<WriteIMinMax, [SMTA100_IEU]>;
def : WriteRes<WriteREV8, [SMTA100_IEU]>;

let Latency = 2 in {
  def : WriteRes<WriteSHXADD, [SMTA100_IEU]>;
  def : WriteRes<WriteSHXADD32, [SMTA100_IEU]>;
  def : WriteRes<WriteCLMUL, [SMTA100_IEU]>;
}

// Single-bit instructions
def : WriteRes<WriteSingleBit, [SMTA100_IEU]>;
def : WriteRes<WriteSingleBitImm, [SMTA100_IEU]>;
def : WriteRes<WriteBEXT, [SMTA100_IEU]>;
def : WriteRes<WriteBEXTI, [SMTA100_IEU]>;

// Memory/Atomic memory
let Latency = 4 in {
  def : WriteRes<WriteSTB, [SMTA100_LS]>;
  def : WriteRes<WriteSTH, [SMTA100_LS]>;
  def : WriteRes<WriteSTW, [SMTA100_LS]>;
  def : WriteRes<WriteSTD, [SMTA100_LS]>;
  def : WriteRes<WriteFST16, [SMTA100_LS]>;
  def : WriteRes<WriteFST32, [SMTA100_LS]>;
  def : WriteRes<WriteFST64, [SMTA100_LS]>;

  def : WriteRes<WriteLDB, [SMTA100_LS]>;
  def : WriteRes<WriteLDH, [SMTA100_LS]>;
  def : WriteRes<WriteLDW, [SMTA100_LS]>;
  def : WriteRes<WriteLDD, [SMTA100_LS]>;
  def : WriteRes<WriteFLD16, [SMTA100_LS]>;
  def : WriteRes<WriteFLD32, [SMTA100_LS]>;
  def : WriteRes<WriteFLD64, [SMTA100_LS]>;
}

// Atomics
let Latency = 8 in {
  def : WriteRes<WriteAtomicSTW, [SMTA100_LS]>;
  def : WriteRes<WriteAtomicSTD, [SMTA100_LS]>;
  def : WriteRes<WriteAtomicLDW, [SMTA100_LS]>;
  def : WriteRes<WriteAtomicLDD, [SMTA100_LS]>;
}

let Latency = 12 in {
  def : WriteRes<WriteAtomicW, [SMTA100_LS]>;
  def : WriteRes<WriteAtomicD, [SMTA100_LS]>;
}

// Floating point units Half precision
let Latency = 4 in {
  def : WriteRes<WriteFAdd16, [SMTA100_FP]>;
  def : WriteRes<WriteFMul16, [SMTA100_FP]>;
  def : WriteRes<WriteFSGNJ16, [SMTA100_FP]>;
  def : WriteRes<WriteFMinMax16, [SMTA100_FP]>;
}
def : WriteRes<WriteFMA16, [SMTA100_FP]> { let Latency = 5; }

let Latency = 12, ReleaseAtCycles = [12] in {
  def :  WriteRes<WriteFDiv16, [SMTA100_FP]>;
  def :  WriteRes<WriteFSqrt16, [SMTA100_FP]>;
}

// Single precision
let Latency = 4 in {
  def : WriteRes<WriteFAdd32, [SMTA100_FP]>;
  def : WriteRes<WriteFMul32, [SMTA100_FP]>;
  def : WriteRes<WriteFSGNJ32, [SMTA100_FP]>;
  def : WriteRes<WriteFMinMax32, [SMTA100_FP]>;
}
def : WriteRes<WriteFMA32, [SMTA100_FP]> { let Latency = 5; }

let Latency = 15, ReleaseAtCycles = [15] in {
  def :  WriteRes<WriteFDiv32, [SMTA100_FP]>;
  def :  WriteRes<WriteFSqrt32, [SMTA100_FP]>;
}

// Double precision
let Latency = 5 in {
  def : WriteRes<WriteFAdd64, [SMTA100_FP]>;
  def : WriteRes<WriteFMul64, [SMTA100_FP]>;
  def : WriteRes<WriteFSGNJ64, [SMTA100_FP]>;
}
def : WriteRes<WriteFMinMax64, [SMTA100_FP]> { let Latency = 4; }
def : WriteRes<WriteFMA64, [SMTA100_FP]> { let Latency = 6; }

let Latency = 22, ReleaseAtCycles = [22] in {
  def :  WriteRes<WriteFDiv64, [SMTA100_FP]>;
  def :  WriteRes<WriteFSqrt64, [SMTA100_FP]>;
}

// Conversions
let Latency = 6 in {
  def : WriteRes<WriteFCvtF16ToI32, [SMTA100_IEU]>;
  def : WriteRes<WriteFCvtF32ToI32, [SMTA100_IEU]>;
  def : WriteRes<WriteFCvtF32ToI64, [SMTA100_IEU]>;
  def : WriteRes<WriteFCvtF64ToI64, [SMTA100_IEU]>;
  def : WriteRes<WriteFCvtF64ToI32, [SMTA100_IEU]>;
  def : WriteRes<WriteFCvtF16ToI64, [SMTA100_IEU]>;
}

let Latency = 4 in {
  def : WriteRes<WriteFCvtI32ToF16, [SMTA100_IEU]>;
  def : WriteRes<WriteFCvtI32ToF32, [SMTA100_IEU]>;
  def : WriteRes<WriteFCvtI32ToF64, [SMTA100_IEU]>;
  def : WriteRes<WriteFCvtI64ToF16, [SMTA100_IEU]>;
  def : WriteRes<WriteFCvtI64ToF32, [SMTA100_IEU]>;
  def : WriteRes<WriteFCvtI64ToF64, [SMTA100_IEU]>;
  def : WriteRes<WriteFCvtF16ToF32, [SMTA100_FP]>;
  def : WriteRes<WriteFCvtF16ToF64, [SMTA100_FP]>;
  def : WriteRes<WriteFCvtF32ToF16, [SMTA100_FP]>;
  def : WriteRes<WriteFCvtF32ToF64, [SMTA100_FP]>;
  def : WriteRes<WriteFCvtF64ToF16, [SMTA100_FP]>;
  def : WriteRes<WriteFCvtF64ToF32, [SMTA100_FP]>;
}

let Latency = 6 in {
  def : WriteRes<WriteFClass16, [SMTA100_FP]>;
  def : WriteRes<WriteFClass32, [SMTA100_FP]>;
  def : WriteRes<WriteFClass64, [SMTA100_FP]>;

  def : WriteRes<WriteFCmp16, [SMTA100_FP]>;
  def : WriteRes<WriteFCmp32, [SMTA100_FP]>;
  def : WriteRes<WriteFCmp64, [SMTA100_FP]>;

  def : WriteRes<WriteFMovF32ToI32, [SMTA100_IEU]>;
  def : WriteRes<WriteFMovF16ToI16, [SMTA100_IEU]>;
}

let Latency = 4 in {
  def : WriteRes<WriteFMovI16ToF16, [SMTA100_IEU]>;
  def : WriteRes<WriteFMovF64ToI64, [SMTA100_IEU]>;
  def : WriteRes<WriteFMovI64ToF64, [SMTA100_IEU]>;
  def : WriteRes<WriteFMovI32ToF32, [SMTA100_IEU]>;
}

// 6. Configuration-Setting Instructions
def : WriteRes<WriteVSETVLI, [SMTA100_IEUA]>;
def : WriteRes<WriteVSETIVLI, [SMTA100_IEUA]>;
def : WriteRes<WriteVSETVL, [SMTA100_IEUA]>;

// 7. Vector Loads and Stores
foreach mx = SchedMxList in {
  defvar IsWorstCase = SMTA100IsWorstCaseMX<mx, SchedMxList>.c;

  // Unit-stride loads and stores
  defvar VLDELat = GetLMULValue<[3, 3, 4, 4, 5, 9, 16], mx>.c;
  defvar VLDEOcc = GetLMULValue<[1, 1, 2, 3, 5, 9, 17], mx>.c;
  let Latency = VLDELat, ReleaseAtCycles = [VLDEOcc] in
    defm "" : LMULWriteResMX<"WriteVLDE", [SMTA100_VLSU], mx, IsWorstCase>;

  defvar VSTELatAndOcc = GetLMULValue<[2, 2, 3, 3, 6, 9, 21], mx>.c;
  let Latency = VSTELatAndOcc, ReleaseAtCycles = [VSTELatAndOcc] in
    defm "" : LMULWriteResMX<"WriteVSTE", [SMTA100_VLSU], mx, IsWorstCase>;

  defvar VLDFFLatAndOcc = GetLMULValue<[8, 8, 9, 10, 14, 18, 26], mx>.c;
  let Latency = VLDFFLatAndOcc, ReleaseAtCycles = [VLDFFLatAndOcc] in
    defm "" : LMULWriteResMX<"WriteVLDFF", [SMTA100_VLSU], mx, IsWorstCase>;

  // Mask loads and stores
  let Latency = 3, ReleaseAtCycles = [3] in
    defm "" : LMULWriteResMX<"WriteVLDM", [SMTA100_VLSU], mx, IsWorstCase>;

  let Latency = 2, ReleaseAtCycles = [2] in
    defm "" : LMULWriteResMX<"WriteVSTM", [SMTA100_VLSU], mx, IsWorstCase>;

  // Strided and indexed loads and stores
  foreach eew = [8, 16, 32, 64] in {
    defvar StridedLdLatAndOcc = !cond(
      !eq(eew, 8)  : ConstValueUntilLMULThenDoubleBase<"MF4", 20, 36, mx>.c,
      !eq(eew, 16) : ConstValueUntilLMULThenDouble<"MF4", 18, mx>.c,
      !eq(eew, 32) : ConstValueUntilLMULThenDouble<"MF2", 20, mx>.c,
      !eq(eew, 64) : ConstValueUntilLMULThenDouble<"M1",  24, mx>.c,
    );
    let Latency = StridedLdLatAndOcc, ReleaseAtCycles = [StridedLdLatAndOcc] in
      defm "" : LMULWriteResMX<"WriteVLDS"  # eew, [SMTA100_VLSU], mx, IsWorstCase>;

    defvar  StridedStLatAndOcc = SMTA100GetVLMAX<mx, eew>.val;
    let Latency = StridedStLatAndOcc, ReleaseAtCycles = [StridedStLatAndOcc] in
      defm "" : LMULWriteResMX<"WriteVSTS"  # eew, [SMTA100_VLSU], mx, IsWorstCase>;

    defvar IndexedLdLatAndOcc = !cond(
      !eq(eew, 8)  : ConstValueUntilLMULThenDoubleBase<"MF4", 24, 35, mx>.c,
      !eq(eew, 16) : ConstValueUntilLMULThenDouble<"MF4", 20, mx>.c,
      !eq(eew, 32) : ConstValueUntilLMULThenDouble<"MF2", 24, mx>.c,
      !eq(eew, 64) : ConstValueUntilLMULThenDouble<"M1",  31, mx>.c,
    );
    let Latency = IndexedLdLatAndOcc, ReleaseAtCycles = [IndexedLdLatAndOcc] in {
      defm "" : LMULWriteResMX<"WriteVLDUX" # eew, [SMTA100_VLSU], mx, IsWorstCase>;
      defm "" : LMULWriteResMX<"WriteVLDOX" # eew, [SMTA100_VLSU], mx, IsWorstCase>;
    }

    defvar IndexedStLatAndOcc = !cond(
      !eq(eew, 8)  : ConstValueUntilLMULThenDouble<"MF8", 19, mx>.c,
      !eq(eew, 16) : ConstValueUntilLMULThenDouble<"MF4", 20, mx>.c,
      !eq(eew, 32) : ConstValueUntilLMULThenDouble<"MF2", 24, mx>.c,
      !eq(eew, 64) : ConstValueUntilLMULThenDouble<"M1",  28, mx>.c,
    );
    let Latency = IndexedStLatAndOcc, ReleaseAtCycles = [IndexedStLatAndOcc] in {
      defm "" : LMULWriteResMX<"WriteVSTUX" # eew, [SMTA100_VLSU], mx, IsWorstCase>;
      defm "" : LMULWriteResMX<"WriteVSTOX" # eew, [SMTA100_VLSU], mx, IsWorstCase>;
    }
  }
}

// Segmented loads and stores
foreach mx = SchedMxList in {
  foreach nf=2-8 in {
    defvar IsWorstCase = SMTA100IsWorstCaseMX<mx, SchedMxList>.c;

    // Base value is for MF8; doubles for each LMUL step above MF8.
    defvar UnitStrideLd = !cond (
      !eq(nf, 2): 6,
      !eq(nf, 3): 10,
      !eq(nf, 4): 12,
      !eq(nf, 5): 84,
      !eq(nf, 6): 102,
      !eq(nf, 7): 118,
      !eq(nf, 8): 135,
    );
    defvar UnitStrideSt = !cond (
      !eq(nf, 2): 3,
      !eq(nf, 3): 6,
      !eq(nf, 4): 6,
      !eq(nf, 5): 84,
      !eq(nf, 6): 102,
      !eq(nf, 7): 118,
      !eq(nf, 8): 135,
    );
    defvar StrideIdxLd = !cond (
      !eq(nf, 2): 21,
      !eq(nf, 3): 24,
      !eq(nf, 4): 27,
      !eq(nf, 5): 84,
      !eq(nf, 6): 102,
      !eq(nf, 7): 118,
      !eq(nf, 8): 135,
    );
    defvar StrideIdxSt = !cond (
      !eq(nf, 2): 17,
      !eq(nf, 3): 18,
      !eq(nf, 4): 19,
      !eq(nf, 5): 84,
      !eq(nf, 6): 102,
      !eq(nf, 7): 118,
      !eq(nf, 8): 135,
    );
    defvar UnitStrideLdLatAndOcc =
        ConstValueUntilLMULThenDouble<"MF8", UnitStrideLd, mx>.c;
    defvar UnitStrideStLatAndOcc =
        ConstValueUntilLMULThenDouble<"MF8", UnitStrideSt, mx>.c;
    defvar StrideIdxLdLatAndOcc =
        ConstValueUntilLMULThenDouble<"MF8", StrideIdxLd, mx>.c;
    defvar StrideIdxStLatAndOcc =
        ConstValueUntilLMULThenDouble<"MF8", StrideIdxSt, mx>.c;
    foreach eew = [8, 16, 32, 64] in {
      // Unit-stride segmented load
      let Latency = UnitStrideLdLatAndOcc, ReleaseAtCycles = [UnitStrideLdLatAndOcc] in
        defm "" : LMULWriteResMX<"WriteVLSEG" # nf # "e" #eew, [SMTA100_VLSU], mx, IsWorstCase>;

      let Latency = UnitStrideStLatAndOcc, ReleaseAtCycles = [UnitStrideStLatAndOcc] in {
        defm "" : LMULWriteResMX<"WriteVSSEG" # nf # "e" #eew, [SMTA100_VLSU], mx, IsWorstCase>;
        // FIXME: change the Latency && ReleaseAtCycles
        defm "" : LMULWriteResMX<"WriteVLSEGFF" # nf # "e" #eew, [SMTA100_VLSU], mx, IsWorstCase>;
      }
      // Strided/indexed segmented
      let Latency = StrideIdxLdLatAndOcc, ReleaseAtCycles = [StrideIdxLdLatAndOcc] in
        defm "" : LMULWriteResMX<"WriteVLSSEG" # nf # "e" #eew, [SMTA100_VLSU], mx, IsWorstCase>;
      let Latency = StrideIdxStLatAndOcc, ReleaseAtCycles = [StrideIdxStLatAndOcc] in {
        defm "" : LMULWriteResMX<"WriteVSSSEG" # nf # "e" #eew, [SMTA100_VLSU], mx, IsWorstCase>;

        // Indexed segmented
        // FIXME: change the latnecy and releaseAtCycles
        defm "" : LMULWriteResMX<"WriteVLOXSEG" # nf # "e" #eew, [SMTA100_VLSU], mx, IsWorstCase>;
        defm "" : LMULWriteResMX<"WriteVLUXSEG" # nf # "e" #eew, [SMTA100_VLSU], mx, IsWorstCase>;
        defm "" : LMULWriteResMX<"WriteVSUXSEG" # nf # "e" #eew, [SMTA100_VLSU], mx, IsWorstCase>;
        defm "" : LMULWriteResMX<"WriteVSOXSEG" # nf # "e" #eew, [SMTA100_VLSU], mx, IsWorstCase>;
      }
    }
  }
}

// Whole register move/load/store
foreach LMul = [1, 2, 4, 8] in {
  defvar WholeLdStLatAndOcc = !cond(
    !eq(LMul, 1) : 3,
    !eq(LMul, 2) : 5,
    !eq(LMul, 4) : 9,
    !eq(LMul, 8) : 17);
  let Latency = WholeLdStLatAndOcc, ReleaseAtCycles = [WholeLdStLatAndOcc] in {
    def : WriteRes<!cast<SchedWrite>("WriteVLD" # LMul # "R"), [SMTA100_VLSU]>;
    def : WriteRes<!cast<SchedWrite>("WriteVST" # LMul # "R"), [SMTA100_VLSU]>;
  }

  defvar VMovLat = !cond(
      !eq(LMul, 1) : 4,
      !eq(LMul, 2) : 5,
      !eq(LMul, 4) : 8,
      !eq(LMul, 8) : 16);
  let Latency = VMovLat, ReleaseAtCycles = [!mul(LMul, 2)] in {
    def : WriteRes<!cast<SchedWrite>("WriteVMov" # LMul # "V"), [SMTA100_VEU0]>;
  }
}

// 11. Vector Integer Arithmetic Instructions
foreach mx = SchedMxList in {
  defvar IsWorstCase = SMTA100IsWorstCaseMX<mx, SchedMxList>.c;

  defvar VIALULat = Get45816Latency<mx>.c;
  defvar VIOcc = ConstOneUntilMF2ThenDouble<mx>.c;
  let Latency = VIALULat, ReleaseAtCycles = [VIOcc] in {
    defm "" : LMULWriteResMX<"WriteVIALUV", [SMTA100_VIEU], mx, IsWorstCase>;
    defm "" : LMULWriteResMX<"WriteVIALUX", [SMTA100_VIEU], mx, IsWorstCase>;
    defm "" : LMULWriteResMX<"WriteVIALUI", [SMTA100_VIEU], mx, IsWorstCase>;
    defm "" : LMULWriteResMX<"WriteVIMinMaxV", [SMTA100_VIEU], mx, IsWorstCase>;
    defm "" : LMULWriteResMX<"WriteVIMinMaxX", [SMTA100_VIEU], mx, IsWorstCase>;
    defm "" : LMULWriteResMX<"WriteVExtV", [SMTA100_VEU0], mx, IsWorstCase>;
    defm "" : LMULWriteResMX<"WriteVIMergeV", [SMTA100_VIEU], mx, IsWorstCase>;
    defm "" : LMULWriteResMX<"WriteVIMergeX", [SMTA100_VIEU], mx, IsWorstCase>;
    defm "" : LMULWriteResMX<"WriteVIMergeI", [SMTA100_VIEU], mx, IsWorstCase>;
    defm "" : LMULWriteResMX<"WriteVIMovV", [SMTA100_VIEU], mx, IsWorstCase>;
    defm "" : LMULWriteResMX<"WriteVIMovX", [SMTA100_VIEU], mx, IsWorstCase>;
    defm "" : LMULWriteResMX<"WriteVIMovI", [SMTA100_VIEU], mx, IsWorstCase>;
    defm "" : LMULWriteResMX<"WriteVShiftV", [SMTA100_VEU0], mx, IsWorstCase>;
    defm "" : LMULWriteResMX<"WriteVShiftX", [SMTA100_VEU0], mx, IsWorstCase>;
    defm "" : LMULWriteResMX<"WriteVShiftI", [SMTA100_VEU0], mx, IsWorstCase>;
    defm "" : LMULWriteResMX<"WriteVICALUV", [SMTA100_VEU0], mx, IsWorstCase>;
    defm "" : LMULWriteResMX<"WriteVICALUX", [SMTA100_VEU0], mx, IsWorstCase>;
    defm "" : LMULWriteResMX<"WriteVICALUI", [SMTA100_VEU0], mx, IsWorstCase>;
  }

  // let Latency = VIALULat in
  // def SMTA100WriteVCOPY_ # mx : SchedWriteRes<[]>;

  // Type     ReleaseAtCycle                   Latency
  // e8  = [1, 1, 2, 3, 4, 8, 16]     [4, 4, 4, 6, 6, 8, 16]
  // e16 = [   1, 2, 3, 5, 8, 16]     [   4, 4, 6, 10, 10, 16]
  // e32 = [      2, 3, 5, 9, 18]     [      4, 6, 10, 18, 18]
  // e64 = [         3, 5, 9, 34]     [         6, 10, 18, 34]
  // We use the worst-case until we can split the SEW.
  defvar VICmpCarryLat = GetLMULValue<[4, 4, 4, 6, 10, 18, 34], mx>.c;
  defvar VICmpCarryOcc = GetLMULValue<[1, 1, 2, 3,  5,  9, 34], mx>.c;
  let Latency = VICmpCarryLat, ReleaseAtCycles = [VICmpCarryOcc] in {
    defm "" : LMULWriteResMX<"WriteVICALUMV", [SMTA100_VEU0], mx, IsWorstCase>;
    defm "" : LMULWriteResMX<"WriteVICALUMX", [SMTA100_VEU0], mx, IsWorstCase>;
    defm "" : LMULWriteResMX<"WriteVICALUMI", [SMTA100_VEU0], mx, IsWorstCase>;
    defm "" : LMULWriteResMX<"WriteVICmpV", [SMTA100_VIEU], mx, IsWorstCase>;
    defm "" : LMULWriteResMX<"WriteVICmpX", [SMTA100_VIEU], mx, IsWorstCase>;
    defm "" : LMULWriteResMX<"WriteVICmpI", [SMTA100_VIEU], mx, IsWorstCase>;
  }

  // Type      ReleaseAtCycle                   Latency
  // e8  = [1, 1, 1, 2,  4,  8,  16]     [4, 4, 4, 4,  5,  8,  16]
  // e16 = [   1, 1, 2,  4,  8,  16]     [   4, 4, 4,  5,  8,  16]
  // e32 = [      2, 4,  8,  16, 32]     [      5, 5,  8,  16, 32]
  // e64 = [         16, 32, 64, 128]    [         16, 32, 64, 128]
  // We use the worst-case until we can split the SEW.
  defvar VIMulLat = GetLMULValue<[4, 4, 5, 16, 32, 64, 128], mx>.c;
  defvar VIMulOcc = GetLMULValue<[1, 1, 2, 16, 32, 64, 128], mx>.c;
  let Latency = VIMulLat, ReleaseAtCycles = [VIMulOcc] in {
    defm "" : LMULWriteResMX<"WriteVIMulV", [SMTA100_VIEU], mx, IsWorstCase>;
    defm "" : LMULWriteResMX<"WriteVIMulX", [SMTA100_VIEU], mx, IsWorstCase>;
    defm "" : LMULWriteResMX<"WriteVIMulAddV", [SMTA100_VIEU], mx, IsWorstCase>;
    defm "" : LMULWriteResMX<"WriteVIMulAddX", [SMTA100_VIEU], mx, IsWorstCase>;
  }
}

// Widening
foreach mx = SchedMxListW in {
  defvar IsWorstCase = SMTA100IsWorstCaseMX<mx, SchedMxListW>.c;

  defvar VIWALULat = GetLMULValue<[4, 4, 4, 5, 8, 16], mx>.c;
  defvar VIWALUOcc = ConstOneUntilMF4ThenDouble<mx>.c;
  let Latency = VIWALULat, ReleaseAtCycles = [VIWALUOcc]  in {
    defm "" : LMULWriteResMX<"WriteVIWALUV", [SMTA100_VIEU], mx, IsWorstCase>;
    defm "" : LMULWriteResMX<"WriteVIWALUX", [SMTA100_VIEU], mx, IsWorstCase>;
    defm "" : LMULWriteResMX<"WriteVIWALUI", [SMTA100_VIEU], mx, IsWorstCase>;
  }

  // Latency: e8/e16 = 4/5/8/16, e32 = 5/8/16/32
  // ReleaseAtCycle: e8/e16 = 2/4/8/16, e32 = 4/8/16/32
  // We use the worst-case until we can split the SEW
  defvar VIWMulLat = ConstValueUntilLMULThenDoubleBase<"M1", 5, 8, mx>.c;
  defvar VIWMulOcc = ConstValueUntilLMULThenDouble<"MF2", 4, mx>.c;
  let Latency = VIWMulLat, ReleaseAtCycles = [VIWMulOcc]  in {
    defm "" : LMULWriteResMX<"WriteVIWMulV", [SMTA100_VIEU], mx, IsWorstCase>;
    defm "" : LMULWriteResMX<"WriteVIWMulX", [SMTA100_VIEU], mx, IsWorstCase>;
    defm "" : LMULWriteResMX<"WriteVIWMulAddV", [SMTA100_VIEU], mx, IsWorstCase>;
    defm "" : LMULWriteResMX<"WriteVIWMulAddX", [SMTA100_VIEU], mx, IsWorstCase>;
  }
}

// Division and remainder operations
// Pattern of vdivu: 13/27/53/106/212/426/853
// Pattern of vdiv: 12/12/12/22/44/88/176
// Pattern of vremu: 12/12/12/22/44/88/176
// Pattern of vrem: 13/13/13/24/48/96/192
// We use for all: 12/12/12/24/48/96/192
// TODO: Create separate WriteVIRem to more closely match the latencies
foreach mx = SchedMxList in {
  foreach sew = SchedSEWSet<mx>.val in {
    defvar IsWorstCase = SMTA100IsWorstCaseMXSEW<mx, sew, SchedMxList>.c;

    // Not pipelined
    defvar VIDivLatAndOcc = ConstValueUntilLMULThenDouble<"MF2", 12, mx>.c;
    let Latency = VIDivLatAndOcc, ReleaseAtCycles = [VIDivLatAndOcc] in {
      defm "" : LMULSEWWriteResMXSEW<"WriteVIDivV", [SMTA100_VEU0], mx, sew, IsWorstCase>;
      defm "" : LMULSEWWriteResMXSEW<"WriteVIDivX", [SMTA100_VEU0], mx, sew, IsWorstCase>;
    }
  }
}

// Narrowing Shift and Clips
foreach mx = SchedMxListW in {
  defvar IsWorstCase = SMTA100IsWorstCaseMX<mx, SchedMxListW>.c;

  defvar VNarrowingLat = GetLMULValue<[4, 4, 4, 5, 8, 16], mx>.c;
  defvar VNarrowingOcc = ConstValueUntilLMULThenDouble<"MF8", 1, mx>.c;
  let Latency = VNarrowingLat, ReleaseAtCycles = [VNarrowingOcc] in {
    defm "" : LMULWriteResMX<"WriteVNShiftV", [SMTA100_VEU0], mx, IsWorstCase>;
    defm "" : LMULWriteResMX<"WriteVNShiftX", [SMTA100_VEU0], mx, IsWorstCase>;
    defm "" : LMULWriteResMX<"WriteVNShiftI", [SMTA100_VEU0], mx, IsWorstCase>;
    defm "" : LMULWriteResMX<"WriteVNClipV", [SMTA100_VEU0], mx, IsWorstCase>;
    defm "" : LMULWriteResMX<"WriteVNClipX", [SMTA100_VEU0], mx, IsWorstCase>;
    defm "" : LMULWriteResMX<"WriteVNClipI", [SMTA100_VEU0], mx, IsWorstCase>;
  }
}

// 12. Vector Fixed-Point Arithmetic Instructions
foreach mx = SchedMxList in {
  defvar IsWorstCase = SMTA100IsWorstCaseMX<mx, SchedMxList>.c;

  defvar VSALUOcc = ConstOneUntilMF2ThenDouble<mx>.c;
  let Latency = Get45816Latency<mx>.c, ReleaseAtCycles = [VSALUOcc] in {
    defm "" : LMULWriteResMX<"WriteVSALUV", [SMTA100_VIEU], mx, IsWorstCase>;
    defm "" : LMULWriteResMX<"WriteVSALUX", [SMTA100_VIEU], mx, IsWorstCase>;
    defm "" : LMULWriteResMX<"WriteVSALUI", [SMTA100_VIEU], mx, IsWorstCase>;
    defm "" : LMULWriteResMX<"WriteVAALUV", [SMTA100_VIEU], mx, IsWorstCase>;
    defm "" : LMULWriteResMX<"WriteVAALUX", [SMTA100_VIEU], mx, IsWorstCase>;
  }

  // Latency : e8/e16 = 4/5/8/16, e32 = 5/8/16/32, e64 = 16/32/64/128
  // ReleaseAtCycles : e8/e16 = 2/4/8/16, e32 = 4/8/16/32, e64 = 16/32/64/128
  // We use the worst-case until we can split the SEW.
  defvar VSMulLatAndOcc = ConstValueUntilLMULThenDouble<"M1", 16, mx>.c;
  // TODO: change WriteVSMulV/X to be defined with LMULSEWSchedWrites
  let Latency = VSMulLatAndOcc, ReleaseAtCycles = [VSMulLatAndOcc] in {
    defm "" : LMULWriteResMX<"WriteVSMulV", [SMTA100_VIEU], mx, IsWorstCase>;
    defm "" : LMULWriteResMX<"WriteVSMulX", [SMTA100_VIEU], mx, IsWorstCase>;
  }

  defvar VSShiftOcc = ConstOneUntilMF2ThenDouble<mx>.c;
  let Latency = Get45816Latency<mx>.c, ReleaseAtCycles = [VSShiftOcc] in {
    defm "" : LMULWriteResMX<"WriteVSShiftV", [SMTA100_VEU0], mx, IsWorstCase>;
    defm "" : LMULWriteResMX<"WriteVSShiftX", [SMTA100_VEU0], mx, IsWorstCase>;
    defm "" : LMULWriteResMX<"WriteVSShiftI", [SMTA100_VEU0], mx, IsWorstCase>;
  }
}

// 13. Vector Floating-Point Instructions
foreach mx = SchedMxListF in {
  foreach sew = SchedSEWSet<mx, isF=1>.val in {
    defvar IsWorstCase = SMTA100IsWorstCaseMXSEW<mx, sew, SchedMxListF, isF=1>.c;
    defvar VFOcc = !if(!eq(sew, 64),
        ConstOneUntilMF2ThenDouble<mx>.c,
        ConstValueUntilLMULThenDouble<"M1", 4, mx>.c);

    defvar VFALULat = !if(!eq(sew, 64), Get45816Latency<mx>.c,
                          ConstValueUntilLMULThenDouble<"M1", 4, mx>.c);
    let Latency = VFALULat, ReleaseAtCycles = [VFOcc] in {
      defm "" : LMULSEWWriteResMXSEW<"WriteVFALUV", [SMTA100_VFPU], mx, sew, IsWorstCase>;
      defm "" : LMULSEWWriteResMXSEW<"WriteVFALUF", [SMTA100_VFPU], mx, sew, IsWorstCase>;
      defm "" : LMULSEWWriteResMXSEW<"WriteVFMinMaxV", [SMTA100_VFPU], mx, sew, IsWorstCase>;
      defm "" : LMULSEWWriteResMXSEW<"WriteVFMinMaxF", [SMTA100_VFPU], mx, sew, IsWorstCase>;
      defm "" : LMULSEWWriteResMXSEW<"WriteVFCvtIToFV", [SMTA100_VEU0], mx, sew, IsWorstCase>;
    }

    defvar VFMulVLat = !if(!eq(sew, 64), ConstValueUntilLMULThenDoubleBase<"M4", 5, 8, mx>.c,
                           ConstValueUntilLMULThenDoubleBase<"M2", 6, 10, mx>.c);
    defvar VFMulVOcc = !if(!eq(sew, 64), ConstOneUntilMF2ThenDouble<mx>.c,
                           ConstValueUntilLMULThenDouble<"M1", 5, mx>.c);
    let Latency = VFMulVLat, ReleaseAtCycles = [VFMulVOcc] in
      defm "" : LMULSEWWriteResMXSEW<"WriteVFMulV", [SMTA100_VFPU], mx, sew, IsWorstCase>;

    defvar VFMulFOcc = !if(!eq(sew, 64), ConstValueUntilLMULThenDoubleBase<"M4", 5, 8, mx>.c,
                          ConstValueUntilLMULThenDoubleBase<"M2", 5, 8, mx>.c);
    let Latency = VFMulVLat, ReleaseAtCycles = [VFOcc] in
      defm "" : LMULSEWWriteResMXSEW<"WriteVFMulF", [SMTA100_VFPU], mx, sew, IsWorstCase>;

    defvar VFRecpVLat = ConstValueUntilLMULThenDouble<"MF2", 4, mx>.c;
    defvar VFRecpVOcc = ConstValueUntilLMULThenDouble<"MF4", 2, mx>.c;
    let Latency = VFRecpVLat, ReleaseAtCycles = [VFRecpVOcc] in
      defm "" : LMULSEWWriteResMXSEW<"WriteVFRecpV", [SMTA100_VEU0], mx, sew, IsWorstCase>;

    let Latency = Get45816Latency<mx>.c, ReleaseAtCycles = [ConstOneUntilMF2ThenDouble<mx>.c] in {
      defm "" : LMULSEWWriteResMXSEW<"WriteVFSgnjV", [SMTA100_VEU0], mx, sew, IsWorstCase>;
      defm "" : LMULSEWWriteResMXSEW<"WriteVFSgnjF", [SMTA100_VEU0], mx, sew, IsWorstCase>;
    }

    defvar VFMulAddLat = !if(!eq(sew, 64),
        ConstValueUntilLMULThenDoubleBase<"M4", 5, 8, mx>.c,
        ConstValueUntilLMULThenDoubleBase<"M2", 6, 8, mx>.c
    );
    let Latency = VFMulAddLat, ReleaseAtCycles = [VFOcc] in {
      defm "" : LMULSEWWriteResMXSEW<"WriteVFMulAddV", [SMTA100_VFPU], mx, sew, IsWorstCase>;
      defm "" : LMULSEWWriteResMXSEW<"WriteVFMulAddF", [SMTA100_VFPU], mx, sew, IsWorstCase>;
    }
  }
}

foreach mx = SchedMxList in {
  defvar IsWorstCase = SMTA100IsWorstCaseMX<mx, SchedMxList>.c;

  // Latency: e16 = 4/6/10/11/16, e32 = 4/6/10/18/19, e64 = 10/18/34/66
  // ReleaseAtCycles: e16 = 2/3/5/8/16, e32 = 2/3/5/9/19, e64 = 5/9/17/66
  // We use the worst-case until we can split the SEW.
  // TODO: change the WriteVFCvtFToIV to be defined with LMULSEWSchedWrites 
  defvar VFCmpLat = GetLMULValue<[10, 10, 10, 10, 18, 34, 66], mx>.c;
  defvar VFCmpOcc = GetLMULValue<[5, 5, 5, 5, 9, 17, 66], mx>.c;
  let Latency = VFCmpLat, ReleaseAtCycles = [VFCmpOcc] in {
    defm "" : LMULWriteResMX<"WriteVFCmpV", [SMTA100_VFPU], mx, IsWorstCase>;
    defm "" : LMULWriteResMX<"WriteVFCmpF", [SMTA100_VFPU], mx, IsWorstCase>;
  }

  defvar VFClassLat = ConstValueUntilLMULThenDouble<"MF2", 4, mx>.c;
  defvar VFClassOcc = ConstValueUntilLMULThenDouble<"MF4", 2, mx>.c;
  let Latency = VFClassLat, ReleaseAtCycles = [VFClassOcc] in {
    defm "" : LMULWriteResMX<"WriteVFClassV", [SMTA100_VEU0], mx, IsWorstCase>;
  }

  let Latency = Get45816Latency<mx>.c, ReleaseAtCycles = [ConstOneUntilMF2ThenDouble<mx>.c] in {
    defm "" : LMULWriteResMX<"WriteVFMergeV", [SMTA100_VEU0], mx, IsWorstCase>;
    defm "" : LMULWriteResMX<"WriteVFMovV", [SMTA100_VEU0], mx, IsWorstCase>;
  }

  // Latency: e16/e32 = 4/5/8/16 e64 = 4/8/16/32
  // ReleaseAtCycles: e16/e32 = 2/4/8/16, e64 = 4/8/16/32
  // We use the worst-case until we can split the SEW.
  // TODO: change the WriteVFCvtFToIV to be defined with LMULSEWSchedWrites 
  defvar VFCvtFToILatAndOcc = ConstValueUntilLMULThenDouble<"M1", 4, mx>.c;
  let Latency = VFCvtFToILatAndOcc, ReleaseAtCycles = [VFCvtFToILatAndOcc] in
    defm "" : LMULWriteResMX<"WriteVFCvtFToIV", [SMTA100_VEU0], mx, IsWorstCase>;
}

// Widening
foreach mx = SchedMxListW in {
  foreach sew = SchedSEWSet<mx, isF=0, isWidening=1>.val in {
    defvar IsWorstCase = SMTA100IsWorstCaseMXSEW<mx, sew, SchedMxListW>.c;

    defvar VFWCvtIToFLat = !if(!eq(sew, 16),
        GetLMULValue<[4, 4, 4, 5, 8, 16], mx>.c,
        ConstValueUntilLMULThenDouble<"M1", 4, mx>.c
    );
    defvar VFWCvtIToFOcc = !if(!eq(sew, 16),
        ConstOneUntilMF4ThenDouble<mx>.c,
        ConstValueUntilLMULThenDouble<"M1", 4, mx>.c
    );
    let Latency = VFWCvtIToFLat, ReleaseAtCycles = [VFWCvtIToFOcc] in {
      defm "" : LMULSEWWriteResMXSEW<"WriteVFWCvtIToFV", [SMTA100_VEU0], mx, sew, IsWorstCase>;
    }
  }
}

foreach mx = SchedMxListFW in {
  defvar IsWorstCase = SMTA100IsWorstCaseMX<mx, SchedMxListFW>.c;

  // Latency: e16/e32 = 4/5/8/16 e64 = 4/8/16/32
  // ReleaseAtCycles: e16/e32 = 2/4/8/16, e64 = 4/8/16/32
  // We use the worst-case until we can split the SEW.
  // TODO: change the WriteVFCvtFToIV to be defined with LMULSEWSchedWrites 
  defvar VFWCvtFToILatAndVOcc = ConstValueUntilLMULThenDouble<"M1", 4, mx>.c;
  let Latency = VFWCvtFToILatAndVOcc, ReleaseAtCycles = [VFWCvtFToILatAndVOcc] in {
    defm "" : LMULWriteResMX<"WriteVFWCvtFToIV", [SMTA100_VEU0], mx, IsWorstCase>;
  }
}

foreach mx = SchedMxListFW in {
  foreach sew = SchedSEWSet<mx, isF=1, isWidening=1>.val in {
    defvar IsWorstCase = SMTA100IsWorstCaseMXSEW<mx, sew, SchedMxListFW, isF=1>.c;

    defvar VFWCvtFToFVLat = !if(!eq(sew, 16),
        GetLMULValue<[4, 4, 4, 5, 8, 16], mx>.c,
        ConstValueUntilLMULThenDouble<"M1", 4, mx>.c
    );
    defvar VFWCvtFToFVOcc = !if(!eq(sew, 16),
        ConstOneUntilMF4ThenDouble<mx>.c,
        ConstValueUntilLMULThenDouble<"M1", 4, mx>.c
    );
    let Latency = VFWCvtFToFVLat, ReleaseAtCycles = [VFWCvtFToFVOcc] in {
      defm "" : LMULSEWWriteResMXSEW<"WriteVFWCvtFToFV", [SMTA100_VEU0], mx, sew, IsWorstCase>;
    }

    // Latency for vfwsub/vfwadd.vv, vfwsub/vfwadd.vf: 4/8/16/32
    // ReleaseAtCycles for vfwsub/vfwadd.vv, vfwsub/vfwadd.vf: 2/4/8/16/32
    // Latency for vfwsub/vfwadd.wv, vfwsub/vfwadd.wf: 4/8/16/32/64
    // ReleaseAtCycles for vfwsub/vfwadd.wv, vfwsub/vfwadd.wf: 4/8/16/32/64
    // We use the worst-case
    defvar VFWALULat = ConstValueUntilLMULThenDoubleBase<"MF2", 5, 8, mx>.c;
    defvar VFWALUOcc = ConstValueUntilLMULThenDouble<"MF4", 4, mx>.c;
    // TODO: Split .wf/.wv variants into separate scheduling classes
    let Latency = VFWALULat, ReleaseAtCycles = [VFWALUOcc] in {
      defm "" : LMULSEWWriteResMXSEW<"WriteVFWALUV", [SMTA100_VFPU], mx, sew, IsWorstCase>;
      defm "" : LMULSEWWriteResMXSEW<"WriteVFWALUF", [SMTA100_VFPU], mx, sew, IsWorstCase>;
    }

    defvar VFWMulLat = ConstValueUntilLMULThenDoubleBase<"M1", 5, 8, mx>.c;
    defvar VFWMulOcc = ConstValueUntilLMULThenDouble<"MF2", 2, mx>.c;
    let Latency = VFWMulLat, ReleaseAtCycles = [VFWMulOcc] in {
      defm "" : LMULSEWWriteResMXSEW<"WriteVFWMulF", [SMTA100_VFPU], mx, sew, IsWorstCase>;
      defm "" : LMULSEWWriteResMXSEW<"WriteVFWMulV", [SMTA100_VFPU], mx, sew, IsWorstCase>;
    }

    // Latency for vfwmacc, vfwnmacc, etc: e16 = 5/8/16/32; e32 = 6/8/16/32
    defvar VFWMulAddVLat = !if(!eq(sew, 16),
      ConstValueUntilLMULThenDoubleBase<"M1", 5, 8, mx>.c,
      ConstValueUntilLMULThenDoubleBase<"M1", 6, 8, mx>.c
    );
    let Latency = VFWMulAddVLat, ReleaseAtCycles = [ConstOneUntilMF2ThenDouble<mx>.c] in {
      defm "" : LMULSEWWriteResMXSEW<"WriteVFWMulAddV", [SMTA100_VFPU], mx, sew, IsWorstCase>;
      defm "" : LMULSEWWriteResMXSEW<"WriteVFWMulAddF", [SMTA100_VFPU], mx, sew, IsWorstCase>;
    }
  }
}

// Narrowing
foreach mx = SchedMxListW in {
  defvar IsWorstCase = SMTA100IsWorstCaseMX<mx, SchedMxListW>.c;

  // Latency: e16 = 4/4/5/8/16 e64 = 4/8/16/32
  // ReleaseAtCycles: e16 = 2/2/4/8/16, e64 = 4/8/16/32
  // We use the worst-case until we can split the SEW.
  // TODO: change the WriteVFCvtFToIV to be defined with LMULSEWSchedWrites
  defvar VFNCvtFToIVLatAndOcc = ConstValueUntilLMULThenDouble<"MF2", 4, mx>.c;
  let Latency = VFNCvtFToIVLatAndOcc, ReleaseAtCycles = [VFNCvtFToIVLatAndOcc] in {
    defm "" : LMULWriteResMX<"WriteVFNCvtFToIV", [SMTA100_VEU0], mx, IsWorstCase>;
  }
}

foreach mx = SchedMxListFW in {
  foreach sew = SchedSEWSet<mx, isF=1, isWidening=1>.val in {
    defvar IsWorstCase = SMTA100IsWorstCaseMXSEW<mx, sew, SchedMxListFW, isF=1>.c;

    defvar VFNCvtToFVLat = !if(!eq(sew, 16),
      GetLMULValue<[4, 4, 4, 5, 8, 16], mx>.c,
      ConstValueUntilLMULThenDouble<"MF2", 4, mx>.c);
    defvar VFNCvtToFVOcc = !if(!eq(sew, 16),
      ConstValueUntilLMULThenDouble<"MF2", 2, mx>.c,
      ConstValueUntilLMULThenDouble<"MF2", 4, mx>.c);
    let Latency = VFNCvtToFVLat, ReleaseAtCycles = [VFNCvtToFVOcc] in {
      defm "" : LMULSEWWriteResMXSEW<"WriteVFNCvtIToFV", [SMTA100_VEU0], mx, sew, IsWorstCase>;
      defm "" : LMULSEWWriteResMXSEW<"WriteVFNCvtFToFV", [SMTA100_VEU0], mx, sew, IsWorstCase>;
    }
  }
}

// Vector Floating-Point Division and Square Root
foreach mx = SchedMxListF in {
  foreach sew = SchedSEWSet<mx, 1>.val in {
    defvar IsWorstCase = SMTA100IsWorstCaseMXSEW<mx, sew, SchedMxListF, 1>.c;

    defvar VFDivFLat = !cond(
      !eq(sew, 16) : GetLMULValue<[17, 17, 32,  69, 129, 267, 534], mx>.c,
      !eq(sew, 32) : GetLMULValue<[58, 58, 58, 100, 256, 433, 834], mx>.c,
      !eq(sew, 64) : GetLMULValue<[48, 48, 48,  48,  96, 192, 384], mx>.c
    );
    defvar VFDivFOcc = !cond(
      !eq(sew, 16) : GetLMULValue<[16, 16, 32, 64, 129, 259, 526], mx>.c,
      !eq(sew, 32) : GetLMULValue<[32, 32, 32, 62, 124, 245, 462], mx>.c,
      !eq(sew, 64) : GetLMULValue<[50, 50, 50, 50,  98, 192, 385], mx>.c
    );
    let Latency = VFDivFLat, ReleaseAtCycles = [VFDivFOcc] in {
      defm "" : LMULSEWWriteResMXSEW<"WriteVFDivF", [SMTA100_VEU0], mx, sew, IsWorstCase>;
    }

    defvar VFDivVLat = !cond(
      !eq(sew, 16) : GetLMULValue<[31,  31,  61,  120, 241, 484, 948], mx>.c,
      !eq(sew, 32) : GetLMULValue<[77,  77,  77,  153, 306, 615, 1228], mx>.c,
      !eq(sew, 64) : GetLMULValue<[160, 160, 160, 160, 320, 641, 1282], mx>.c
    );
    defvar VFDivVOcc = !cond(
      !eq(sew, 16) : GetLMULValue<[18, 18, 35, 66, 129, 252, 497], mx>.c,
      !eq(sew, 32) : GetLMULValue<[31, 31, 31, 56, 105, 204, 404], mx>.c,
      !eq(sew, 64) : GetLMULValue<[62, 62, 62, 62, 110, 207, 399], mx>.c
    );
    let Latency = VFDivVLat, ReleaseAtCycles = [VFDivVOcc] in {
      defm "" : LMULSEWWriteResMXSEW<"WriteVFDivV", [SMTA100_VEU0], mx, sew, IsWorstCase>;
    }
  }
}

foreach mx = SchedMxListF in {
  foreach sew = SchedSEWSet<mx, 1>.val in {
    defvar IsWorstCase = SMTA100IsWorstCaseMXSEW<mx, sew, SchedMxListF, 1>.c;

    defvar VFSqrtVLat = !cond(
      !eq(sew, 16) : GetLMULValue<[29,  29,  55,  112, 225, 450, 898], mx>.c,
      !eq(sew, 32) : GetLMULValue<[65,  65,  737, 137, 272, 544, 1086], mx>.c,
      !eq(sew, 64) : GetLMULValue<[130, 130, 130, 130, 263, 534, 1067], mx>.c
    );
    defvar VFSqrtVOcc = !cond(
      !eq(sew, 16) : GetLMULValue<[16, 16, 30, 58, 115, 229, 457], mx>.c,
      !eq(sew, 32) : GetLMULValue<[28, 28, 28, 52, 101, 197, 394], mx>.c,
      !eq(sew, 64) : GetLMULValue<[55, 55, 55, 55, 104, 198, 391], mx>.c
    );
    let Latency = VFSqrtVLat, ReleaseAtCycles = [VFSqrtVOcc] in {
      defm "" : LMULSEWWriteResMXSEW<"WriteVFSqrtV", [SMTA100_VEU0], mx, sew, IsWorstCase>;
    }
  }
}

// 14. Vector Reduction Operations
foreach mx = SchedMxList in {
  foreach sew = SchedSEWSet<mx>.val in {
    defvar IsWorstCase = SMTA100IsWorstCaseMXSEW<mx, sew, SchedMxList>.c;

    defvar VIRedLat = GetLMULValue<[5, 7, 11, 19, 35, 67, 131], mx>.c;
    defvar VIRedOcc = GetLMULValue<[2, 2,  4,  8, 16, 33, 131], mx>.c;
    let Latency = VIRedLat, ReleaseAtCycles = [VIRedOcc] in {
      defm "" : LMULSEWWriteResMXSEW<"WriteVIRedMinMaxV_From", [SMTA100_VIEU], mx, sew, IsWorstCase>;

      // Pattern for vredsum:                  5/7/11/19/35/67/131
      // Pattern for vredand, vredor, vredxor: 4/6/10/18/34/66/131
      // They are grouped together, so we use the worst-case vredsum latency.
      // TODO: split vredand, vredor, vredxor into separate scheduling classe.
      defm "" : LMULSEWWriteResMXSEW<"WriteVIRedV_From", [SMTA100_VIEU], mx, sew, IsWorstCase>;
    }
  }
}

foreach mx = SchedMxListWRed in {
  foreach sew = SchedSEWSet<mx, 0, 1>.val in {
    defvar IsWorstCase = SMTA100IsWorstCaseMXSEW<mx, sew, SchedMxListWRed>.c;

    defvar VIRedLat = GetLMULValue<[5, 7, 11, 19, 35, 67, 131], mx>.c;
    defvar VIRedOcc = GetLMULValue<[2, 2, 4, 8, 16, 34, 132], mx>.c;
    let Latency = VIRedLat, ReleaseAtCycles = [VIRedOcc] in {
      defm "" : LMULSEWWriteResMXSEW<"WriteVIWRedV_From", [SMTA100_VIEU], mx, sew, IsWorstCase>;
    }
  }
}

foreach mx = SchedMxListF in {
  foreach sew = SchedSEWSet<mx, 1>.val in {
    defvar IsWorstCase = SMTA100IsWorstCaseMXSEW<mx, sew, SchedMxListF, 1>.c;

    defvar VFRedLat = !cond(
      !eq(sew, 16) : GetLMULValue<[15, 15, 21, 33, 57, 105, 202], mx>.c,
      !eq(sew, 32) : GetLMULValue<[18, 18, 18, 30, 54, 102, 198], mx>.c,
      !eq(sew, 64) : GetLMULValue<[27, 27, 27, 27, 51,  99, 196], mx>.c
    );
    defvar VFRedOcc = !cond(
      !eq(sew, 16) : GetLMULValue<[7,  7,  10, 16, 28, 53, 202], mx>.c,
      !eq(sew, 32) : GetLMULValue<[8,  8,   8, 14, 26, 51, 198], mx>.c,
      !eq(sew, 64) : GetLMULValue<[13, 13, 13, 13, 25, 50, 196], mx>.c
    );
    let Latency = VFRedLat, ReleaseAtCycles = [VFRedOcc] in {
      defm "" : LMULSEWWriteResMXSEW<"WriteVFRedV_From", [SMTA100_VFPU], mx, sew, IsWorstCase>;
      defm "" : LMULSEWWriteResMXSEW<"WriteVFRedMinMaxV_From", [SMTA100_VFPU], mx, sew, IsWorstCase>;
    }
  }
}

foreach mx = SchedMxListF in {
  foreach sew = SchedSEWSet<mx, 1>.val in {
    defvar IsWorstCase = SMTA100IsWorstCaseMXSEW<mx, sew, SchedMxListF, 1>.c;

    // Compute latency based on SEW
    defvar VFRedOVLat = !cond(
      !eq(sew, 16) : ConstValueUntilLMULThenDouble<"MF4", 48, mx>.c,
      !eq(sew, 32) : ConstValueUntilLMULThenDouble<"MF2", 48, mx>.c,
      !eq(sew, 64) : ConstValueUntilLMULThenDouble<"M1",  49, mx>.c
    );
    defvar VFRedOVOcc = !cond(
      !eq(sew, 16) : GetLMULValue<[23, 23, 47, 96, 192, 384, 1537], mx>.c,
      !eq(sew, 32) : GetLMULValue<[23, 23, 23, 47,  96, 192, 769], mx>.c,
      !eq(sew, 64) : GetLMULValue<[23, 23, 23, 23,  47,  96, 385], mx>.c
    );
    let Latency = VFRedOVLat, ReleaseAtCycles = [VFRedOVOcc] in {
      defm "" : LMULSEWWriteResMXSEW<"WriteVFRedOV_From", [SMTA100_VFPU], mx, sew, IsWorstCase>;
    }
  }
}

foreach mx = SchedMxListFWRed in {
  foreach sew = SchedSEWSet<mx, 1, 1>.val in {
    defvar IsWorstCase = SMTA100IsWorstCaseMXSEW<mx, sew, SchedMxListFWRed, 1>.c;

    defvar VFRedOVLat = !cond(
      !eq(sew, 16) : ConstValueUntilLMULThenDouble<"MF4", 64, mx>.c,
      !eq(sew, 32) : ConstValueUntilLMULThenDouble<"MF2", 65, mx>.c,
    );
    defvar VFRedOVOcc = !cond(
      !eq(sew, 16) : GetLMULValue<[31, 31, 63, 127, 255, 512, 2050], mx>.c,
      !eq(sew, 32) : GetLMULValue<[31, 31, 31,  63, 127, 257, 1026], mx>.c,
    );
    let Latency = VFRedOVLat, ReleaseAtCycles = [VFRedOVOcc] in {
      defm "" : LMULSEWWriteResMXSEW<"WriteVFWRedV_From", [SMTA100_VFPU], mx, sew, IsWorstCase>;
      defm "" : LMULSEWWriteResMXSEW<"WriteVFWRedOV_From", [SMTA100_VFPU], mx, sew, IsWorstCase>;
    }
  }
}

// 15. Vector Mask Instructions
foreach mx = SchedMxList in {
  defvar IsWorstCase = SMTA100IsWorstCaseMX<mx, SchedMxList>.c;

  let Latency = 4, ReleaseAtCycles = [1] in
    defm "" : LMULWriteResMX<"WriteVMALUV", [SMTA100_VEU0], mx, IsWorstCase>;

  let Latency = 4, ReleaseAtCycles = [ConstValueUntilLMULThenDouble<"M2", 1, mx>.c] in
    defm "" : LMULWriteResMX<"WriteVMSFSV", [SMTA100_VEU0], mx, IsWorstCase>;

  let Latency = ConstValueUntilLMULThenDouble<"MF2", 4, mx>.c, ReleaseAtCycles = [2] in
    defm "" : LMULWriteResMX<"WriteVMPopV", [SMTA100_VEU0], mx, IsWorstCase>;

  let Latency = 6, ReleaseAtCycles = [2] in
    defm "" : LMULWriteResMX<"WriteVMFFSV", [SMTA100_VEU0], mx, IsWorstCase>;

  defvar VIotaLat = ConstValueUntilLMULThenDouble<"MF2", 4, mx>.c;
  defvar VIotaOcc = ConstOneUntilMF8ThenDouble<mx>.c;
  let Latency = VIotaLat, ReleaseAtCycles = [VIotaOcc] in {
    defm "" : LMULWriteResMX<"WriteVIotaV", [SMTA100_VEU0], mx, IsWorstCase>;
    defm "" : LMULWriteResMX<"WriteVIdxV", [SMTA100_VEU0], mx, IsWorstCase>;
  }
}

// 16. Vector Permutation Instructions
// Slide
foreach mx = SchedMxList in {
  defvar IsWorstCase = SMTA100IsWorstCaseMX<mx, SchedMxList>.c;

  defvar VSlideUpLat = ConstValueUntilLMULThenDouble<"MF2", 4, mx>.c;
  defvar VSlideUpOcc = ConstOneUntilMF8ThenDouble<mx>.c;
  let Latency = VSlideUpLat, ReleaseAtCycles =[VSlideUpOcc] in {
    defm "" : LMULWriteResMX<"WriteVSlideUpX", [SMTA100_VEU0], mx, IsWorstCase>;
    defm "" : LMULWriteResMX<"WriteVSlideUpI", [SMTA100_VEU0], mx, IsWorstCase>;
    defm "" : LMULWriteResMX<"WriteVISlide1Up", [SMTA100_VEU0], mx, IsWorstCase>;
    defm "" : LMULWriteResMX<"WriteVFSlide1Up", [SMTA100_VEU0], mx, IsWorstCase>;
  }
  
  defvar VSlideDownLat = GetLMULValue<[4, 4, 5, 9, 17, 33, 65], mx>.c;
  defvar VSlideDownOcc = GetLMULValue<[1, 3, 5, 9, 17, 33, 65], mx>.c;
  let Latency = VSlideDownLat, ReleaseAtCycles =[VSlideDownOcc] in {
    defm "" : LMULWriteResMX<"WriteVSlideDownX", [SMTA100_VEU0], mx, IsWorstCase>;
    defm "" : LMULWriteResMX<"WriteVSlideDownI", [SMTA100_VEU0], mx, IsWorstCase>;
  }

  defvar VSlide1DownLat = GetLMULValue<[4, 5, 5, 9, 17, 33, 65], mx>.c;
  let Latency = VSlide1DownLat, ReleaseAtCycles =[VSlideDownOcc] in {
    defm "" : LMULWriteResMX<"WriteVISlide1Down", [SMTA100_VEU0], mx, IsWorstCase>;
    defm "" : LMULWriteResMX<"WriteVFSlide1Down", [SMTA100_VEU0], mx, IsWorstCase>;
  }
}

// ReleaseAtCycles is 1/1/1/1/2/3/6, but we can't set based on MX for now
// TODO: Split this into separate WriteRes for each MX
let Latency = 6, ReleaseAtCycles = [6] in {
  def : WriteRes<WriteVMovXS, [SMTA100_VEU0]>;
}

// ReleaseAtCycles is 1/1/1/1/1/2/4, but we can't set based on MX for now
// TODO: Split this into separate WriteRes for each MX
let Latency = 4, ReleaseAtCycles = [4] in {
  def : WriteRes<WriteVMovSX, [SMTA100_VEU0]>;
  def : WriteRes<WriteVMovFS, [SMTA100_VEU0]>;
  def : WriteRes<WriteVMovSF, [SMTA100_VEU0]>;
}

// Integer LMUL Gather and Compress
foreach mx = SchedMxList in {
  defvar IsWorstCase = SMTA100IsWorstCaseMX<mx, SchedMxList>.c;

  defvar VRGatherLat = ConstValueUntilLMULThenDoubleBase<"M1", 4, 8, mx>.c;
  defvar VRGatherOcc = ConstOneUntilMF8ThenDouble<mx>.c;
  let Latency = VRGatherLat, ReleaseAtCycles = [VRGatherOcc] in {
    defm "" : LMULWriteResMX<"WriteVRGatherVX", [SMTA100_VEU0], mx, IsWorstCase>;
    defm "" : LMULWriteResMX<"WriteVRGatherVI", [SMTA100_VEU0], mx, IsWorstCase>;
  }

  foreach sew = SchedSEWSet<mx>.val in {
    defvar IsWorstCaseSEW = SMTA100IsWorstCaseMXSEW<mx, sew, SchedMxList>.c;

    defvar VRGatherVVLat = GetLMULValue<[4, 4, 16, 64, 256, 1025, 4100], mx>.c;
    defvar VRGatherVVOcc = GetLMULValue<[1, 4, 16, 64, 256, 1025, 4100], mx>.c;
    let Latency = VRGatherVVLat, ReleaseAtCycles = [VRGatherVVOcc] in
      defm "" : LMULSEWWriteResMXSEW<"WriteVRGatherVV", [SMTA100_VEU0], mx, sew, IsWorstCaseSEW>;

    // For sew == 8, latency is half of the other cases, except for the fractional LMULs (const 4 cycles)
    defvar VRGatherEI16LatAndOcc = !if(!eq(sew, 8),
      GetLMULValue<[4, 8, 32, 128, 512, 2050, 2050], mx>.c,
      GetLMULValue<[4, 4, 16,  64, 256, 1025, 4100], mx>.c);
    let Latency = VRGatherEI16LatAndOcc, ReleaseAtCycles = [VRGatherEI16LatAndOcc] in {
      defm "" : LMULSEWWriteResMXSEW<"WriteVRGatherEI16VV", [SMTA100_VEU0], mx, sew, IsWorstCaseSEW>;
    }

    defvar VCompressVLat = GetLMULValue<[4, 4, 10, 36, 126, 528, 2082], mx>.c;
    defvar VCompressVOcc = GetLMULValue<[1, 3, 10, 36, 136, 528, 2082], mx>.c;
    let Latency = VCompressVLat, ReleaseAtCycles = [VCompressVOcc] in {
      defm "" : LMULSEWWriteResMXSEW<"WriteVCompressV", [SMTA100_VEU0], mx, sew, IsWorstCaseSEW>;
    }
  }
}

// Others
def : WriteRes<WriteCSR, [SMTA100_IEU]>;
def : WriteRes<WriteNop, [SMTA100_IEU]>;
def : WriteRes<WriteRdVLENB, [SMTA100_IEUA]>;

// // Assign scheduling info to COPY instructions.
// // Note: We try NOT to assign ProcResource but only latency to vector COPY because
// // those resources might prevent those COPYs from showing up to the scheulder
// // until it's too late.
// // Specifically, for a given COPY of live-in (physical) register, ideally we want it
// // to be visible to the top available queue as early as possible so that it can be scheduled
// // at the beginning of the function. Assigning resource to vector COPYs might risk
// // creating structural hazard that prevents those COPYs from even entering the available
// // queue and as a consequence, sinking those COPYs.
// // I see little difference on assigning ProcResource to scalar COPY or not, so I'm still
// // assigning WriteIALU to it.
// def SMTA100CopySchedWriteVariant : SchedWriteVariant<[
//   SchedVar<SchedPredicate<[{ TII->isVRegCopy(MI, /*LMUL=*/1) }]>, [SMTA100WriteVCOPY_M1]>,
//   SchedVar<SchedPredicate<[{ TII->isVRegCopy(MI, /*LMUL=*/2) }]>, [SMTA100WriteVCOPY_M2]>,
//   SchedVar<SchedPredicate<[{ TII->isVRegCopy(MI, /*LMUL=*/4) }]>, [SMTA100WriteVCOPY_M4]>,
//   SchedVar<SchedPredicate<[{ TII->isVRegCopy(MI, /*LMUL=*/8) }]>, [SMTA100WriteVCOPY_M8]>,
//   SchedVar<NoSchedPred,                                           [WriteIALU]>
// ]>;
// def : InstRW<[SMTA100CopySchedWriteVariant], (instrs COPY)>;

// Vector Crypto
foreach mx = SchedMxList in {
  defvar IsWorstCase = SMTA100IsWorstCaseMX<mx, SchedMxList>.c;

  defvar Lat = ConstValueUntilLMULThenDouble<"MF2", 4, mx>.c;
  let Latency = Lat, ReleaseAtCycles = [ConstOneUntilMF8ThenDouble<mx>.c] in {
    // Zvbb
    defm "" : LMULWriteResMX<"WriteVBREVV",   [SMTA100_VEU0], mx, IsWorstCase>;
    defm "" : LMULWriteResMX<"WriteVCLZV",    [SMTA100_VEU0], mx, IsWorstCase>;
    defm "" : LMULWriteResMX<"WriteVCTZV",    [SMTA100_VEU0], mx, IsWorstCase>;
    defm "" : LMULWriteResMX<"WriteVCPOPV",   [SMTA100_VEU0], mx, IsWorstCase>;
    defm "" : LMULWriteResMX<"WriteVBREV8V",  [SMTA100_VEU0], mx, IsWorstCase>;
    defm "" : LMULWriteResMX<"WriteVREV8V",   [SMTA100_VEU0], mx, IsWorstCase>;
  }

  let Latency = Get45816Latency<mx>.c, ReleaseAtCycles = [ConstOneUntilMF2ThenDouble<mx>.c] in {
    // Zvkb
    // VANDN uses WriteVIALU[V|X|I]
    defm "" : LMULWriteResMX<"WriteVRotV",    [SMTA100_VEU0], mx, IsWorstCase>;
    defm "" : LMULWriteResMX<"WriteVRotX",    [SMTA100_VEU0], mx, IsWorstCase>;
    defm "" : LMULWriteResMX<"WriteVRotI",    [SMTA100_VEU0], mx, IsWorstCase>;
  }

  defvar VCLAndVGLatAndOcc = ConstValueUntilLMULThenDouble<"M1", 8, mx>.c;
  let Latency = VCLAndVGLatAndOcc, ReleaseAtCycles = [VCLAndVGLatAndOcc] in {
    // Zvbc
    defm "" : LMULWriteResMX<"WriteVCLMULV", [SMTA100_VEU0], mx, IsWorstCase>;
    defm "" : LMULWriteResMX<"WriteVCLMULX", [SMTA100_VEU0], mx, IsWorstCase>;

    // Zvkg
    defm "" : LMULWriteResMX<"WriteVGHSHV",   [SMTA100_VEU0], mx, IsWorstCase>;
    defm "" : LMULWriteResMX<"WriteVGMULV",   [SMTA100_VEU0], mx, IsWorstCase>;
  }

  // ZvknhaOrZvknhb
  //  e32 = 16/32/64
  //  e64 = 21/37
  // TODO: Shold set vsha2ch.vv / vsha2cl.vv SEW-aware?
  defvar VSHALatandOcc = ConstValueUntilLMULThenDouble<"M2", 16, mx>.c;
  let Latency = VSHALatandOcc, ReleaseAtCycles = [VSHALatandOcc] in {
    defm "" : LMULWriteResMX<"WriteVSHA2CHV", [SMTA100_VIEU], mx, IsWorstCase>;
    defm "" : LMULWriteResMX<"WriteVSHA2CLV", [SMTA100_VIEU], mx, IsWorstCase>;
  }

  // vsha2ms.vv latency depends on SEW: doubling SEW shifts the doubling
  // threshold right by one LMUL step.
  //  e32 = 16/32/64
  //  e64 = 21/37
  defvar ZvknhSEWs = !listremove(SchedSEWSet<mx>.val, [8, 16]);
  // Smallest SEW (=32) carries the highest latency, so the WorstCase fallback
  // is designated to the smallest SEW at the largest LMUL.
  defvar SmallestZvknhSEW = !head(ZvknhSEWs);
  foreach sew = ZvknhSEWs in {
    defvar IsWorstCaseVSHA2MSV = !and(IsWorstCase, !eq(sew, SmallestZvknhSEW));
    defvar VSHA2MSLatandOcc =
        ConstValueUntilLMULThenDouble<!if(!eq(sew, 64), "M4", "M2"), 4, mx>.c;
    let Latency = VSHA2MSLatandOcc, ReleaseAtCycles = [VSHA2MSLatandOcc] in
      defm "" : LMULSEWWriteResMXSEW<"WriteVSHA2MSV", [SMTA100_VIEU], mx, sew,
                                     IsWorstCaseVSHA2MSV>;
  }

  // Zvkned
  defvar VASELatandOcc = ConstValueUntilLMULThenDouble<"M1", 8, mx>.c;
  let Latency = VASELatandOcc, ReleaseAtCycles = [VASELatandOcc] in {
    defm "" : LMULWriteResMX<"WriteVAESMVV",  [SMTA100_VEU0], mx, IsWorstCase>;
    defm "" : LMULWriteResMX<"WriteVAESKF1V", [SMTA100_VEU0], mx, IsWorstCase>;
    defm "" : LMULWriteResMX<"WriteVAESKF2V", [SMTA100_VEU0], mx, IsWorstCase>;
    defm "" : LMULWriteResMX<"WriteVAESZV",   [SMTA100_VEU0], mx, IsWorstCase>;
  }

  defvar VSM3CLatAndOcc = ConstValueUntilLMULThenDouble<"M2", 8, mx>.c;
  let Latency = VSM3CLatAndOcc, ReleaseAtCycles = [VSM3CLatAndOcc] in {
    defm "" : LMULWriteResMX<"WriteVSM3CV",   [SMTA100_VIEU], mx, IsWorstCase>;
    defm "" : LMULWriteResMX<"WriteVSM3MEV",  [SMTA100_VIEU], mx, IsWorstCase>;
  }

  defvar VSM4LatAndOcc =  ConstValueUntilLMULThenDouble<"M1", 8, mx>.c;
  let Latency = 3, ReleaseAtCycles = [VSM4LatAndOcc] in {
    defm "" : LMULWriteResMX<"WriteVSM4KV",   [SMTA100_VIEU], mx, IsWorstCase>;
    defm "" : LMULWriteResMX<"WriteVSM4RV",   [SMTA100_VIEU], mx, IsWorstCase>;
  }
}

foreach mx = SchedMxListW in {
  defvar IsWorstCase = SMTA100IsWorstCaseMX<mx, SchedMxListW>.c;

  defvar VWSLat = GetLMULValue<[4, 4, 4, 5, 8, 16], mx>.c;
  defvar VWSOcc = ConstOneUntilMF4ThenDouble<mx>.c;
  let Latency = VWSLat, ReleaseAtCycles = [VWSOcc] in {
    defm "" : LMULWriteResMX<"WriteVWSLLV",   [SMTA100_VEU0], mx, IsWorstCase>;
    defm "" : LMULWriteResMX<"WriteVWSLLX",   [SMTA100_VEU0], mx, IsWorstCase>;
    defm "" : LMULWriteResMX<"WriteVWSLLI",   [SMTA100_VEU0], mx, IsWorstCase>;
  }
}

//===----------------------------------------------------------------------===//
// Bypass and advance
def : ReadAdvance<ReadJmp, 0>;
def : ReadAdvance<ReadJalr, 0>;
def : ReadAdvance<ReadCSR, 0>;
def : ReadAdvance<ReadStoreData, 0>;
def : ReadAdvance<ReadMemBase, 0>;
def : ReadAdvance<ReadIALU, 0>;
def : ReadAdvance<ReadIALU32, 0>;
def : ReadAdvance<ReadShiftImm, 0>;
def : ReadAdvance<ReadShiftImm32, 0>;
def : ReadAdvance<ReadShiftReg, 0>;
def : ReadAdvance<ReadShiftReg32, 0>;
def : ReadAdvance<ReadIDiv, 0>;
def : ReadAdvance<ReadIDiv32, 0>;
def : ReadAdvance<ReadIRem, 0>;
def : ReadAdvance<ReadIRem32, 0>;
def : ReadAdvance<ReadIMul, 0>;
def : ReadAdvance<ReadIMul32, 0>;
def : ReadAdvance<ReadAtomicWA, 0>;
def : ReadAdvance<ReadAtomicWD, 0>;
def : ReadAdvance<ReadAtomicDA, 0>;
def : ReadAdvance<ReadAtomicDD, 0>;
def : ReadAdvance<ReadAtomicLDW, 0>;
def : ReadAdvance<ReadAtomicLDD, 0>;
def : ReadAdvance<ReadAtomicSTW, 0>;
def : ReadAdvance<ReadAtomicSTD, 0>;
def : ReadAdvance<ReadFStoreData, 0>;
def : ReadAdvance<ReadFMemBase, 0>;
def : ReadAdvance<ReadFAdd16, 0>;
def : ReadAdvance<ReadFAdd32, 0>;
def : ReadAdvance<ReadFAdd64, 0>;
def : ReadAdvance<ReadFMul16, 0>;
def : ReadAdvance<ReadFMA16, 0>;
def : ReadAdvance<ReadFMA16Addend, 0>;
def : ReadAdvance<ReadFMul32, 0>;
def : ReadAdvance<ReadFMul64, 0>;
def : ReadAdvance<ReadFMA32, 0>;
def : ReadAdvance<ReadFMA32Addend, 0>;
def : ReadAdvance<ReadFMA64, 0>;
def : ReadAdvance<ReadFMA64Addend, 0>;
def : ReadAdvance<ReadFDiv16, 0>;
def : ReadAdvance<ReadFDiv32, 0>;
def : ReadAdvance<ReadFDiv64, 0>;
def : ReadAdvance<ReadFSqrt16, 0>;
def : ReadAdvance<ReadFSqrt32, 0>;
def : ReadAdvance<ReadFSqrt64, 0>;
def : ReadAdvance<ReadFCmp16, 0>;
def : ReadAdvance<ReadFCmp32, 0>;
def : ReadAdvance<ReadFCmp64, 0>;
def : ReadAdvance<ReadFSGNJ16, 0>;
def : ReadAdvance<ReadFSGNJ32, 0>;
def : ReadAdvance<ReadFSGNJ64, 0>;
def : ReadAdvance<ReadFMinMax16, 0>;
def : ReadAdvance<ReadFMinMax32, 0>;
def : ReadAdvance<ReadFMinMax64, 0>;
def : ReadAdvance<ReadFCvtF16ToI32, 0>;
def : ReadAdvance<ReadFCvtF16ToI64, 0>;
def : ReadAdvance<ReadFCvtF32ToI32, 0>;
def : ReadAdvance<ReadFCvtF32ToI64, 0>;
def : ReadAdvance<ReadFCvtF64ToI32, 0>;
def : ReadAdvance<ReadFCvtF64ToI64, 0>;
def : ReadAdvance<ReadFCvtI32ToF16, 0>;
def : ReadAdvance<ReadFCvtI32ToF32, 0>;
def : ReadAdvance<ReadFCvtI32ToF64, 0>;
def : ReadAdvance<ReadFCvtI64ToF16, 0>;
def : ReadAdvance<ReadFCvtI64ToF32, 0>;
def : ReadAdvance<ReadFCvtI64ToF64, 0>;
def : ReadAdvance<ReadFCvtF32ToF64, 0>;
def : ReadAdvance<ReadFCvtF64ToF32, 0>;
def : ReadAdvance<ReadFCvtF16ToF32, 0>;
def : ReadAdvance<ReadFCvtF32ToF16, 0>;
def : ReadAdvance<ReadFCvtF16ToF64, 0>;
def : ReadAdvance<ReadFCvtF64ToF16, 0>;
def : ReadAdvance<ReadFMovF16ToI16, 0>;
def : ReadAdvance<ReadFMovI16ToF16, 0>;
def : ReadAdvance<ReadFMovF32ToI32, 0>;
def : ReadAdvance<ReadFMovI32ToF32, 0>;
def : ReadAdvance<ReadFMovF64ToI64, 0>;
def : ReadAdvance<ReadFMovI64ToF64, 0>;
def : ReadAdvance<ReadFClass16, 0>;
def : ReadAdvance<ReadFClass32, 0>;
def : ReadAdvance<ReadFClass64, 0>;

// Bitmanip
def : ReadAdvance<ReadRotateImm, 0>;
def : ReadAdvance<ReadRotateImm32, 0>;
def : ReadAdvance<ReadRotateReg, 0>;
def : ReadAdvance<ReadRotateReg32, 0>;
def : ReadAdvance<ReadCLZ, 0>;
def : ReadAdvance<ReadCLZ32, 0>;
def : ReadAdvance<ReadCTZ, 0>;
def : ReadAdvance<ReadCTZ32, 0>;
def : ReadAdvance<ReadCPOP, 0>;
def : ReadAdvance<ReadCPOP32, 0>;
def : ReadAdvance<ReadORCB, 0>;
def : ReadAdvance<ReadIMinMax, 0>;
def : ReadAdvance<ReadREV8, 0>;
def : ReadAdvance<ReadSHXADD, 0>;
def : ReadAdvance<ReadSHXADD32, 0>;
def : ReadAdvance<ReadCLMUL, 0>;
// Single-bit instructions
def : ReadAdvance<ReadSingleBit, 0>;
def : ReadAdvance<ReadSingleBitImm, 0>;

// 6. Configuration-Setting Instructions
def : ReadAdvance<ReadVSETVLI, 0>;
def : ReadAdvance<ReadVSETVL, 0>;

// 7. Vector Loads and Stores
def : ReadAdvance<ReadVLDX, 0>;
def : ReadAdvance<ReadVSTX, 0>;
defm "" : LMULReadAdvance<"ReadVSTEV", 0>;
defm "" : LMULReadAdvance<"ReadVSTM", 0>;
def : ReadAdvance<ReadVLDSX, 0>;
def : ReadAdvance<ReadVSTSX, 0>;
defm "" : LMULReadAdvance<"ReadVSTS8V", 0>;
defm "" : LMULReadAdvance<"ReadVSTS16V", 0>;
defm "" : LMULReadAdvance<"ReadVSTS32V", 0>;
defm "" : LMULReadAdvance<"ReadVSTS64V", 0>;
defm "" : LMULReadAdvance<"ReadVLDUXV", 0>;
defm "" : LMULReadAdvance<"ReadVLDOXV", 0>;
defm "" : LMULReadAdvance<"ReadVSTUX8", 0>;
defm "" : LMULReadAdvance<"ReadVSTUX16", 0>;
defm "" : LMULReadAdvance<"ReadVSTUX32", 0>;
defm "" : LMULReadAdvance<"ReadVSTUX64", 0>;
defm "" : LMULReadAdvance<"ReadVSTUXV", 0>;
defm "" : LMULReadAdvance<"ReadVSTUX8V", 0>;
defm "" : LMULReadAdvance<"ReadVSTUX16V", 0>;
defm "" : LMULReadAdvance<"ReadVSTUX32V", 0>;
defm "" : LMULReadAdvance<"ReadVSTUX64V", 0>;
defm "" : LMULReadAdvance<"ReadVSTOX8", 0>;
defm "" : LMULReadAdvance<"ReadVSTOX16", 0>;
defm "" : LMULReadAdvance<"ReadVSTOX32", 0>;
defm "" : LMULReadAdvance<"ReadVSTOX64", 0>;
defm "" : LMULReadAdvance<"ReadVSTOXV", 0>;
defm "" : LMULReadAdvance<"ReadVSTOX8V", 0>;
defm "" : LMULReadAdvance<"ReadVSTOX16V", 0>;
defm "" : LMULReadAdvance<"ReadVSTOX32V", 0>;
defm "" : LMULReadAdvance<"ReadVSTOX64V", 0>;
// LMUL Aware
def : ReadAdvance<ReadVST1R, 0>;
def : ReadAdvance<ReadVST2R, 0>;
def : ReadAdvance<ReadVST4R, 0>;
def : ReadAdvance<ReadVST8R, 0>;

// 11. Vector Integer Arithmetic Instructions
defm : LMULReadAdvance<"ReadVIALUV", 0>;
defm : LMULReadAdvance<"ReadVIALUX", 0>;
defm : LMULReadAdvanceW<"ReadVIWALUV", 0>;
defm : LMULReadAdvanceW<"ReadVIWALUX", 0>;
defm : LMULReadAdvance<"ReadVExtV", 0>;
defm : LMULReadAdvance<"ReadVICALUV", 0>;
defm : LMULReadAdvance<"ReadVICALUX", 0>;
defm : LMULReadAdvance<"ReadVShiftV", 0>;
defm : LMULReadAdvance<"ReadVShiftX", 0>;
defm : LMULReadAdvanceW<"ReadVNShiftV", 0>;
defm : LMULReadAdvanceW<"ReadVNShiftX", 0>;
defm : LMULReadAdvance<"ReadVICmpV", 0>;
defm : LMULReadAdvance<"ReadVICmpX", 0>;
defm : LMULReadAdvance<"ReadVIMinMaxV", 0>;
defm : LMULReadAdvance<"ReadVIMinMaxX", 0>;
defm : LMULReadAdvance<"ReadVIMulV", 0>;
defm : LMULReadAdvance<"ReadVIMulX", 0>;
defm : LMULSEWReadAdvance<"ReadVIDivV", 0>;
defm : LMULSEWReadAdvance<"ReadVIDivX", 0>;
defm : LMULReadAdvanceW<"ReadVIWMulV", 0>;
defm : LMULReadAdvanceW<"ReadVIWMulX", 0>;
defm : LMULReadAdvance<"ReadVIMulAddV", 0>;
defm : LMULReadAdvance<"ReadVIMulAddX", 0>;
defm : LMULReadAdvanceW<"ReadVIWMulAddV", 0>;
defm : LMULReadAdvanceW<"ReadVIWMulAddX", 0>;
defm : LMULReadAdvance<"ReadVIMergeV", 0>;
defm : LMULReadAdvance<"ReadVIMergeX", 0>;
defm : LMULReadAdvance<"ReadVIMovV", 0>;
defm : LMULReadAdvance<"ReadVIMovX", 0>;

// 12. Vector Fixed-Point Arithmetic Instructions
defm "" : LMULReadAdvance<"ReadVSALUV", 0>;
defm "" : LMULReadAdvance<"ReadVSALUX", 0>;
defm "" : LMULReadAdvance<"ReadVAALUV", 0>;
defm "" : LMULReadAdvance<"ReadVAALUX", 0>;
defm "" : LMULReadAdvance<"ReadVSMulV", 0>;
defm "" : LMULReadAdvance<"ReadVSMulX", 0>;
defm "" : LMULReadAdvance<"ReadVSShiftV", 0>;
defm "" : LMULReadAdvance<"ReadVSShiftX", 0>;
defm "" : LMULReadAdvanceW<"ReadVNClipV", 0>;
defm "" : LMULReadAdvanceW<"ReadVNClipX", 0>;

// 13. Vector Floating-Point Instructions
defm "" : LMULSEWReadAdvanceF<"ReadVFALUV", 0>;
defm "" : LMULSEWReadAdvanceF<"ReadVFALUF", 0>;
defm "" : LMULSEWReadAdvanceFW<"ReadVFWALUV", 0>;
defm "" : LMULSEWReadAdvanceFW<"ReadVFWALUF", 0>;
defm "" : LMULSEWReadAdvanceF<"ReadVFMulV", 0>;
defm "" : LMULSEWReadAdvanceF<"ReadVFMulF", 0>;
defm "" : LMULSEWReadAdvanceF<"ReadVFDivV", 0>;
defm "" : LMULSEWReadAdvanceF<"ReadVFDivF", 0>;
defm "" : LMULSEWReadAdvanceFW<"ReadVFWMulV", 0>;
defm "" : LMULSEWReadAdvanceFW<"ReadVFWMulF", 0>;
defm "" : LMULSEWReadAdvanceF<"ReadVFMulAddV", 0>;
defm "" : LMULSEWReadAdvanceF<"ReadVFMulAddF", 0>;
defm "" : LMULSEWReadAdvanceFW<"ReadVFWMulAddV", 0>;
defm "" : LMULSEWReadAdvanceFW<"ReadVFWMulAddF", 0>;
defm "" : LMULSEWReadAdvanceF<"ReadVFSqrtV", 0>;
defm "" : LMULSEWReadAdvanceF<"ReadVFRecpV", 0>;
defm "" : LMULReadAdvance<"ReadVFCmpV", 0>;
defm "" : LMULReadAdvance<"ReadVFCmpF", 0>;
defm "" : LMULSEWReadAdvanceF<"ReadVFMinMaxV", 0>;
defm "" : LMULSEWReadAdvanceF<"ReadVFMinMaxF", 0>;
defm "" : LMULSEWReadAdvanceF<"ReadVFSgnjV", 0>;
defm "" : LMULSEWReadAdvanceF<"ReadVFSgnjF", 0>;
defm "" : LMULReadAdvance<"ReadVFClassV", 0>;
defm "" : LMULReadAdvance<"ReadVFMergeV", 0>;
defm "" : LMULReadAdvance<"ReadVFMergeF", 0>;
defm "" : LMULReadAdvance<"ReadVFMovF", 0>;
defm "" : LMULSEWReadAdvanceF<"ReadVFCvtIToFV", 0>;
defm "" : LMULReadAdvance<"ReadVFCvtFToIV", 0>;
defm "" : LMULSEWReadAdvanceW<"ReadVFWCvtIToFV", 0>;
defm "" : LMULReadAdvanceFW<"ReadVFWCvtFToIV", 0>;
defm "" : LMULSEWReadAdvanceFW<"ReadVFWCvtFToFV", 0>;
defm "" : LMULSEWReadAdvanceFW<"ReadVFNCvtIToFV", 0>;
defm "" : LMULReadAdvanceW<"ReadVFNCvtFToIV", 0>;
defm "" : LMULSEWReadAdvanceFW<"ReadVFNCvtFToFV", 0>;

// 14. Vector Reduction Operations
def : ReadAdvance<ReadVIRedV, 0>;
def : ReadAdvance<ReadVIRedV0, 0>;
def : ReadAdvance<ReadVIWRedV, 0>;
def : ReadAdvance<ReadVIWRedV0, 0>;
def : ReadAdvance<ReadVFRedV, 0>;
def : ReadAdvance<ReadVFRedV0, 0>;
def : ReadAdvance<ReadVFRedOV, 0>;
def : ReadAdvance<ReadVFRedOV0, 0>;
def : ReadAdvance<ReadVFWRedV, 0>;
def : ReadAdvance<ReadVFWRedV0, 0>;
def : ReadAdvance<ReadVFWRedOV, 0>;
def : ReadAdvance<ReadVFWRedOV0, 0>;

// 15. Vector Mask Instructions
defm "" : LMULReadAdvance<"ReadVMALUV", 0>;
defm "" : LMULReadAdvance<"ReadVMPopV", 0>;
defm "" : LMULReadAdvance<"ReadVMFFSV", 0>;
defm "" : LMULReadAdvance<"ReadVMSFSV", 0>;
defm "" : LMULReadAdvance<"ReadVIotaV", 0>;

// 16. Vector Permutation Instructions
def : ReadAdvance<ReadVMovXS, 0>;
def : ReadAdvance<ReadVMovSX_V, 0>;
def : ReadAdvance<ReadVMovSX_X, 0>;
def : ReadAdvance<ReadVMovFS, 0>;
def : ReadAdvance<ReadVMovSF_V, 0>;
def : ReadAdvance<ReadVMovSF_F, 0>;
defm "" : LMULReadAdvance<"ReadVISlideV", 0>;
defm "" : LMULReadAdvance<"ReadVISlideX", 0>;
defm "" : LMULReadAdvance<"ReadVFSlideV", 0>;
defm "" : LMULReadAdvance<"ReadVFSlideF", 0>;
defm "" : LMULSEWReadAdvance<"ReadVRGatherVV_data", 0>;
defm "" : LMULSEWReadAdvance<"ReadVRGatherVV_index", 0>;
defm "" : LMULSEWReadAdvance<"ReadVRGatherEI16VV_data", 0>;
defm "" : LMULSEWReadAdvance<"ReadVRGatherEI16VV_index", 0>;
defm "" : LMULReadAdvance<"ReadVRGatherVX_data", 0>;
defm "" : LMULReadAdvance<"ReadVRGatherVX_index", 0>;
defm "" : LMULReadAdvance<"ReadVRGatherVI_data", 0>;
defm "" : LMULSEWReadAdvance<"ReadVCompressV", 0>;
// LMUL Aware
def : ReadAdvance<ReadVMov1V, 0>;
def : ReadAdvance<ReadVMov2V, 0>;
def : ReadAdvance<ReadVMov4V, 0>;
def : ReadAdvance<ReadVMov8V, 0>;

// Vector Crypto Extensions
// Zvbb
defm "" : LMULReadAdvance<"ReadVBREVV", 0>;
defm "" : LMULReadAdvance<"ReadVCLZV", 0>;
defm "" : LMULReadAdvance<"ReadVCPOPV", 0>;
defm "" : LMULReadAdvance<"ReadVCTZV", 0>;
defm "" : LMULReadAdvance<"ReadVWSLLV", 0>;
defm "" : LMULReadAdvance<"ReadVWSLLX", 0>;
// Zvbc
defm "" : LMULReadAdvance<"ReadVCLMULV", 0>;
defm "" : LMULReadAdvance<"ReadVCLMULX", 0>;
// Zvkb
// VANDN uses ReadVIALU[V|X|I]
defm "" : LMULReadAdvance<"ReadVBREV8V", 0>;
defm "" : LMULReadAdvance<"ReadVREV8V", 0>;
defm "" : LMULReadAdvance<"ReadVRotV", 0>;
defm "" : LMULReadAdvance<"ReadVRotX", 0>;
// Zvkg
defm "" : LMULReadAdvance<"ReadVGHSHV", 0>;
defm "" : LMULReadAdvance<"ReadVGMULV", 0>;
// Zvknha or Zvknhb
defm "" : LMULReadAdvance<"ReadVSHA2CHV", 0>;
defm "" : LMULReadAdvance<"ReadVSHA2CLV", 0>;
defm "" : LMULSEWReadAdvance<"ReadVSHA2MSV", 0>;
// Zvkned
defm "" : LMULReadAdvance<"ReadVAESMVV", 0>;
defm "" : LMULReadAdvance<"ReadVAESKF1V", 0>;
defm "" : LMULReadAdvance<"ReadVAESKF2V", 0>;
defm "" : LMULReadAdvance<"ReadVAESZV", 0>;
// Zvksed
defm "" : LMULReadAdvance<"ReadVSM4KV", 0>;
defm "" : LMULReadAdvance<"ReadVSM4RV", 0>;
// Zbksh
defm "" : LMULReadAdvance<"ReadVSM3CV", 0>;
defm "" : LMULReadAdvance<"ReadVSM3MEV", 0>;

// Others
def : ReadAdvance<ReadVMask, 0>;
def : ReadAdvance<ReadVPassthru_WorstCase, 0>;
foreach mx = SchedMxList in {
  def : ReadAdvance<!cast<SchedRead>("ReadVPassthru_" # mx), 0>;
  foreach sew = SchedSEWSet<mx>.val in
    def : ReadAdvance<!cast<SchedRead>("ReadVPassthru_" # mx  # "_E" # sew), 0>;
}

//===----------------------------------------------------------------------===//
// Unsupported extensions
defm : UnsupportedSchedQ;
defm : UnsupportedSchedZabha;
defm : UnsupportedSchedZbkb;
defm : UnsupportedSchedZbkx;
defm : UnsupportedSchedZfa;
defm : UnsupportedSchedSFB;
defm : UnsupportedSchedXsf;
}
