// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/closure.dart';
import 'package:compiler/src/common.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/diagnostics/diagnostic_listener.dart';
import 'package:compiler/src/elements/entities.dart';
import 'package:compiler/src/inferrer/type_graph_inferrer.dart';
import 'package:compiler/src/js_model/element_map.dart';
import 'package:compiler/src/js_model/js_strategy.dart';
import 'package:kernel/ast.dart' as ir;
import '../equivalence/id_equivalence.dart';
import '../equivalence/id_equivalence_helper.dart';

main(List<String> args) {
  asyncTest(() async {
    Directory dataDir =
        new Directory.fromUri(Platform.script.resolve('callers'));
    await checkTests(dataDir, const CallersDataComputer(),
        args: args, options: [stopAfterTypeInference]);
  });
}

class CallersDataComputer extends DataComputer {
  const CallersDataComputer();

  @override
  void computeMemberData(
      Compiler compiler, MemberEntity member, Map<Id, ActualData> actualMap,
      {bool verbose: false}) {
    JsBackendStrategy backendStrategy = compiler.backendStrategy;
    JsToElementMap elementMap = backendStrategy.elementMap;
    MemberDefinition definition = elementMap.getMemberDefinition(member);
    new CallersIrComputer(
            compiler.reporter,
            actualMap,
            elementMap,
            compiler.globalInference.typesInferrerInternal,
            backendStrategy.closureDataLookup)
        .run(definition.node);
  }
}

/// AST visitor for computing side effects data for a member.
class CallersIrComputer extends IrDataExtractor {
  final TypeGraphInferrer inferrer;
  final JsToElementMap _elementMap;
  final ClosureDataLookup _closureDataLookup;

  CallersIrComputer(DiagnosticReporter reporter, Map<Id, ActualData> actualMap,
      this._elementMap, this.inferrer, this._closureDataLookup)
      : super(reporter, actualMap);

  String getMemberValue(MemberEntity member) {
    Iterable<MemberEntity> callers = inferrer.getCallersOfForTesting(member);
    if (callers != null) {
      List<String> names = callers.map((MemberEntity member) {
        StringBuffer sb = new StringBuffer();
        if (member.enclosingClass != null) {
          sb.write(member.enclosingClass.name);
          sb.write('.');
        }
        sb.write(member.name);
        if (member.isSetter) {
          sb.write('=');
        }
        return sb.toString();
      }).toList()
        ..sort();
      return '[${names.join(',')}]';
    }
    return null;
  }

  @override
  String computeMemberValue(Id id, ir.Member node) {
    return getMemberValue(_elementMap.getMember(node));
  }

  @override
  String computeNodeValue(Id id, ir.TreeNode node) {
    if (node is ir.FunctionExpression || node is ir.FunctionDeclaration) {
      ClosureRepresentationInfo info = _closureDataLookup.getClosureInfo(node);
      return getMemberValue(info.callMethod);
    }
    return null;
  }
}
