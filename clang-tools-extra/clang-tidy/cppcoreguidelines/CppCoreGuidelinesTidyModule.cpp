//===-- CppCoreGuidelinesTidyModule.cpp - clang-tidy ----------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "../ClangTidy.h"
#include "../ClangTidyModule.h"
#include "../ClangTidyModuleRegistry.h"
#include "../bugprone/NarrowingConversionsCheck.h"
#include "../misc/NonPrivateMemberVariablesInClassesCheck.h"
#include "../misc/UnconventionalAssignOperatorCheck.h"
#include "../modernize/AvoidCArraysCheck.h"
#include "../modernize/MacroToEnumCheck.h"
#include "../modernize/UseDefaultMemberInitCheck.h"
#include "../modernize/UseOverrideCheck.h"
#include "../performance/NoexceptDestructorCheck.h"
#include "../performance/NoexceptMoveConstructorCheck.h"
#include "../performance/NoexceptSwapCheck.h"
#include "../readability/MagicNumbersCheck.h"
#include "AvoidCapturingLambdaCoroutinesCheck.h"
#include "AvoidConstOrRefDataMembersCheck.h"
#include "AvoidDoWhileCheck.h"
#include "AvoidGotoCheck.h"
#include "AvoidNonConstGlobalVariablesCheck.h"
#include "AvoidReferenceCoroutineParametersCheck.h"
#include "InitVariablesCheck.h"
#include "InterfacesGlobalInitCheck.h"
#include "MacroUsageCheck.h"
#include "MisleadingCaptureDefaultByValueCheck.h"
#include "MissingStdForwardCheck.h"
#include "NoMallocCheck.h"
#include "NoSuspendWithLockCheck.h"
#include "OwningMemoryCheck.h"
#include "PreferMemberInitializerCheck.h"
#include "ProBoundsArrayToPointerDecayCheck.h"
#include "ProBoundsConstantArrayIndexCheck.h"
#include "ProBoundsPointerArithmeticCheck.h"
#include "ProTypeConstCastCheck.h"
#include "ProTypeCstyleCastCheck.h"
#include "ProTypeMemberInitCheck.h"
#include "ProTypeReinterpretCastCheck.h"
#include "ProTypeStaticCastDowncastCheck.h"
#include "ProTypeUnionAccessCheck.h"
#include "ProTypeVarargCheck.h"
#include "RvalueReferenceParamNotMovedCheck.h"
#include "SlicingCheck.h"
#include "SpecialMemberFunctionsCheck.h"
#include "UseEnumClassCheck.h"
#include "VirtualClassDestructorCheck.h"

namespace clang::tidy {
namespace cppcoreguidelines {

/// A module containing checks of the C++ Core Guidelines
class CppCoreGuidelinesModule : public ClangTidyModule {
public:
  void addCheckFactories(ClangTidyCheckFactories &CheckFactories) override {
    CheckFactories.registerCheck<AvoidCapturingLambdaCoroutinesCheck>(
        "cppcoreguidelines-avoid-capturing-lambda-coroutines");
    CheckFactories.registerCheck<modernize::AvoidCArraysCheck>(
        "cppcoreguidelines-avoid-c-arrays");
    CheckFactories.registerCheck<AvoidConstOrRefDataMembersCheck>(
        "cppcoreguidelines-avoid-const-or-ref-data-members");
    CheckFactories.registerCheck<AvoidDoWhileCheck>(
        "cppcoreguidelines-avoid-do-while");
    CheckFactories.registerCheck<AvoidGotoCheck>(
        "cppcoreguidelines-avoid-goto");
    CheckFactories.registerCheck<readability::MagicNumbersCheck>(
        "cppcoreguidelines-avoid-magic-numbers");
    CheckFactories.registerCheck<AvoidNonConstGlobalVariablesCheck>(
        "cppcoreguidelines-avoid-non-const-global-variables");
    CheckFactories.registerCheck<AvoidReferenceCoroutineParametersCheck>(
        "cppcoreguidelines-avoid-reference-coroutine-parameters");
    CheckFactories.registerCheck<modernize::UseOverrideCheck>(
        "cppcoreguidelines-explicit-virtual-functions");
    CheckFactories.registerCheck<InitVariablesCheck>(
        "cppcoreguidelines-init-variables");
    CheckFactories.registerCheck<InterfacesGlobalInitCheck>(
        "cppcoreguidelines-interfaces-global-init");
    CheckFactories.registerCheck<modernize::MacroToEnumCheck>(
        "cppcoreguidelines-macro-to-enum");
    CheckFactories.registerCheck<MacroUsageCheck>(
        "cppcoreguidelines-macro-usage");
    CheckFactories.registerCheck<MisleadingCaptureDefaultByValueCheck>(
        "cppcoreguidelines-misleading-capture-default-by-value");
    CheckFactories.registerCheck<MissingStdForwardCheck>(
        "cppcoreguidelines-missing-std-forward");
    CheckFactories.registerCheck<bugprone::NarrowingConversionsCheck>(
        "cppcoreguidelines-narrowing-conversions");
    CheckFactories.registerCheck<NoMallocCheck>("cppcoreguidelines-no-malloc");
    CheckFactories.registerCheck<NoSuspendWithLockCheck>(
        "cppcoreguidelines-no-suspend-with-lock");
    CheckFactories.registerCheck<performance::NoexceptDestructorCheck>(
        "cppcoreguidelines-noexcept-destructor");
    CheckFactories.registerCheck<performance::NoexceptMoveConstructorCheck>(
        "cppcoreguidelines-noexcept-move-operations");
    CheckFactories.registerCheck<performance::NoexceptSwapCheck>(
        "cppcoreguidelines-noexcept-swap");
    CheckFactories.registerCheck<misc::NonPrivateMemberVariablesInClassesCheck>(
        "cppcoreguidelines-non-private-member-variables-in-classes");
    CheckFactories.registerCheck<OwningMemoryCheck>(
        "cppcoreguidelines-owning-memory");
    CheckFactories.registerCheck<PreferMemberInitializerCheck>(
        "cppcoreguidelines-prefer-member-initializer");
    CheckFactories.registerCheck<ProBoundsArrayToPointerDecayCheck>(
        "cppcoreguidelines-pro-bounds-array-to-pointer-decay");
    CheckFactories.registerCheck<ProBoundsConstantArrayIndexCheck>(
        "cppcoreguidelines-pro-bounds-constant-array-index");
    CheckFactories.registerCheck<ProBoundsPointerArithmeticCheck>(
        "cppcoreguidelines-pro-bounds-pointer-arithmetic");
    CheckFactories.registerCheck<ProTypeConstCastCheck>(
        "cppcoreguidelines-pro-type-const-cast");
    CheckFactories.registerCheck<ProTypeCstyleCastCheck>(
        "cppcoreguidelines-pro-type-cstyle-cast");
    CheckFactories.registerCheck<ProTypeMemberInitCheck>(
        "cppcoreguidelines-pro-type-member-init");
    CheckFactories.registerCheck<ProTypeReinterpretCastCheck>(
        "cppcoreguidelines-pro-type-reinterpret-cast");
    CheckFactories.registerCheck<ProTypeStaticCastDowncastCheck>(
        "cppcoreguidelines-pro-type-static-cast-downcast");
    CheckFactories.registerCheck<ProTypeUnionAccessCheck>(
        "cppcoreguidelines-pro-type-union-access");
    CheckFactories.registerCheck<ProTypeVarargCheck>(
        "cppcoreguidelines-pro-type-vararg");
    CheckFactories.registerCheck<RvalueReferenceParamNotMovedCheck>(
        "cppcoreguidelines-rvalue-reference-param-not-moved");
    CheckFactories.registerCheck<SpecialMemberFunctionsCheck>(
        "cppcoreguidelines-special-member-functions");
    CheckFactories.registerCheck<SlicingCheck>("cppcoreguidelines-slicing");
    CheckFactories.registerCheck<modernize::UseDefaultMemberInitCheck>(
        "cppcoreguidelines-use-default-member-init");
    CheckFactories.registerCheck<UseEnumClassCheck>(
        "cppcoreguidelines-use-enum-class");
    CheckFactories.registerCheck<misc::UnconventionalAssignOperatorCheck>(
        "cppcoreguidelines-c-copy-assignment-signature");
    CheckFactories.registerCheck<VirtualClassDestructorCheck>(
        "cppcoreguidelines-virtual-class-destructor");
  }

  ClangTidyOptions getModuleOptions() override {
    ClangTidyOptions Options;
    ClangTidyOptions::OptionMap &Opts = Options.CheckOptions;

    Opts["cppcoreguidelines-non-private-member-variables-in-classes."
         "IgnoreClassesWithAllMemberVariablesBeingPublic"] = "true";

    return Options;
  }
};

// Register the LLVMTidyModule using this statically initialized variable.
static ClangTidyModuleRegistry::Add<CppCoreGuidelinesModule>
    X("cppcoreguidelines-module", "Adds checks for the C++ Core Guidelines.");

} // namespace cppcoreguidelines

// This anchor is used to force the linker to link in the generated object file
// and thus register the CppCoreGuidelinesModule.
// NOLINTNEXTLINE(misc-use-internal-linkage)
volatile int CppCoreGuidelinesModuleAnchorSource = 0;

} // namespace clang::tidy
