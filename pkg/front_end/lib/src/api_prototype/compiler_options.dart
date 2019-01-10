// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library front_end.compiler_options;

import 'package:kernel/target/targets.dart' show Target;

import 'diagnostic_message.dart' show DiagnosticMessageHandler;

import 'experimental_flags.dart' show ExperimentalFlag;

import 'file_system.dart' show FileSystem;

import 'standard_file_system.dart' show StandardFileSystem;

export 'diagnostic_message.dart' show DiagnosticMessage;

/// Front-end options relevant to compiler back ends.
///
/// Not intended to be implemented or extended by clients.
class CompilerOptions {
  /// The URI of the root of the Dart SDK (typically a "file:" URI).
  ///
  /// If `null`, the SDK will be searched for using
  /// [Platform.resolvedExecutable] as a starting point.
  Uri sdkRoot;

  /// Uri to a platform libraries specification file.
  ///
  /// A libraries specification file is a JSON file that describes how to map
  /// `dart:*` libraries to URIs in the underlying [fileSystem].  See
  /// `package:front_end/src/base/libraries_specification.dart` for details on
  /// the format.
  ///
  /// If a value is not specified and `compileSdk = true`, the compiler will
  /// infer at a default location under [sdkRoot], typically under
  /// `lib/libraries.json`.
  Uri librariesSpecificationUri;

  DiagnosticMessageHandler onDiagnostic;

  /// URI of the ".packages" file (typically a "file:" URI).
  ///
  /// If `null`, the ".packages" file will be found via the standard
  /// package_config search algorithm.
  ///
  /// If the URI's path component is empty (e.g. `new Uri()`), no packages file
  /// will be used.
  Uri packagesFileUri;

  /// URIs of input summary files (excluding the SDK summary; typically these
  /// will be "file:" URIs).
  ///
  /// These files should be summary files generated by this package (and not the
  /// similarly named summary files from `package:analyzer`.)
  ///
  /// Summaries may be provided in any order, but they should be acyclic and
  /// closed: any libraries that they reference should be defined in either one
  /// of [inputSummaries] or [sdkSummary].
  List<Uri> inputSummaries = [];

  /// URIs of other kernel components to link.
  ///
  /// Commonly used to link the code for the SDK libraries that was compiled
  /// separately. For example, dart2js needs to link the SDK so it can
  /// optimize and tree-shake the code for the application, whereas the VM
  /// always embeds the SDK internally and doesn't need it as part of the
  /// program.
  ///
  /// The components provided here should be closed and acyclic: any libraries
  /// that they reference should be defined in a component in
  /// [linkedDependencies] or any of the [inputSummaries] or [sdkSummary].
  List<Uri> linkedDependencies = [];

  /// URI of the SDK summary file (typically a "file:" URI).
  ///
  /// This should should be a summary previosly generated by this package (and
  /// not the similarly named summary files from `package:analyzer`.)
  ///
  /// If `null` and [compileSdk] is false, the SDK summary will be searched for
  /// at a default location within [sdkRoot].
  Uri sdkSummary;

  /// The declared variables for use by configurable imports and constant
  /// evaluation.
  Map<String, String> declaredVariables;

  /// The [FileSystem] which should be used by the front end to access files.
  ///
  /// All file system access performed by the front end goes through this
  /// mechanism, with one exception: if no value is specified for
  /// [packagesFileUri], the packages file is located using the actual physical
  /// file system.  TODO(paulberry): fix this.
  FileSystem fileSystem = StandardFileSystem.instance;

  /// Whether to generate code for the SDK.
  ///
  /// By default the front end resolves components using a prebuilt SDK summary.
  /// When this option is `true`, [sdkSummary] must be null.
  bool compileSdk = false;

  @deprecated
  bool chaseDependencies;

  /// True if enabling legacy mode (Dart 1 compatibility).
  bool legacyMode = false;

  /// Patch files to apply on the core libraries for a specific target platform.
  ///
  /// Keys in the map are the name of the library with no `dart:` prefix, for
  /// example:
  ///
  ///      {'core': [
  ///         'file:///location/of/core/patch_file1.dart',
  ///         'file:///location/of/core/patch_file2.dart',
  ///         ]}
  ///
  /// The values can be either absolute or relative URIs. Absolute URIs are read
  /// directly, while relative URIs are resolved from the [sdkRoot].
  // TODO(sigmund): provide also a flag to load this data from a file (like
  // libraries.json)
  Map<String, List<Uri>> targetPatches = <String, List<Uri>>{};

  /// Enable or disable experimental features. Features mapping to `true` are
  /// explicitly enabled. Features mapping to `false` are explicitly disabled.
  /// Features not mentioned in the map will have their default value.
  Map<ExperimentalFlag, bool> experimentalFlags = <ExperimentalFlag, bool>{};

  /// The target platform that will consume the compiled code.
  ///
  /// Used to provide platform-specific details to the compiler like:
  ///   * the set of libraries are part of a platform's SDK (e.g. dart:html for
  ///     dart2js, dart:ui for flutter).
  ///
  ///   * what kernel transformations should be applied to the component
  ///     (async/await, mixin inlining, etc).
  ///
  ///   * how to deal with non-standard features like `native` extensions.
  ///
  /// If not specified, the default target is the VM.
  Target target;

  /// Whether to show verbose messages (mainly for debugging and performance
  /// tracking).
  ///
  /// Messages are printed on stdout.
  // TODO(sigmund): improve the diagnotics API to provide mechanism to intercept
  // verbose data (Issue #30056)
  bool verbose = false;

  /// Whether to run extra verification steps to validate that compiled
  /// components are well formed.
  ///
  /// Errors are reported via the [onDiagnostic] callback.
  bool verify = false;

  /// Whether to dump generated components in a text format (also mainly for
  /// debugging).
  ///
  /// Dumped data is printed in stdout.
  bool debugDump = false;

  /// Whether to exclode the platform when serializing the result from a
  /// 'fasta compile' run.
  bool omitPlatform = false;

  /// Whether to set the exit code to non-zero if any problem (including
  /// warning, etc.) is encountered during compilation.
  bool setExitCodeOnProblem = false;

  /// Whether to embed the input sources in generated kernel components.
  ///
  /// The kernel `Component` API includes a `uriToSource` map field that is used
  /// to embed the entire contents of the source files. This part of the kernel
  /// API is in flux and it is not necessary for some tools. Today it is used
  /// for translating error locations and stack traces in the VM.
  // TODO(sigmund): change the default.
  bool embedSourceText = true;

  /// Whether the compiler should throw as soon as it encounters a
  /// compilation error.
  ///
  /// Typically used by developers to debug internals of the compiler.
  bool throwOnErrorsForDebugging = false;

  /// Whether the compiler should throw as soon as it encounters a
  /// compilation warning.
  ///
  /// Typically used by developers to debug internals of the compiler.
  bool throwOnWarningsForDebugging = false;

  /// Whether to generate bytecode.
  bool bytecode = false;

  /// Whether to write a file (e.g. a dill file) when reporting a crash.
  bool writeFileOnCrashReport = true;
}
