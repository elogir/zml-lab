import 'dart:convert';

import 'package:drift/drift.dart';

import '../../models/enums.dart';
import 'database.dart';

String _env(Map<String, String> vars) => jsonEncode(
  vars.entries.map((e) => {'key': e.key, 'value': e.value}).toList(),
);

/// Seeds a representative fleet, saved configs, and a spread of jobs across
/// every status. Runs once, on database creation.
Future<void> seedDatabase(AppDatabase db) async {
  final now = DateTime.now();

  await db.batch((b) {
    b.insertAll(db.machines, [
      MachinesCompanion.insert(
        id: 'orion',
        name: 'orion',
        address: '10.0.4.11',
        user: const Value('ubuntu'),
        vendor: Value(Vendor.nvidia.name),
        gpus: const Value('2× RTX 5090'),
        memory: const Value('2× 32 GB GDDR7'),
      ),
      MachinesCompanion.insert(
        id: 'vega',
        name: 'vega',
        address: '10.0.4.12',
        user: const Value('ubuntu'),
        vendor: Value(Vendor.amd.name),
        gpus: const Value('2× Instinct MI300X'),
        memory: const Value('2× 192 GB HBM3'),
      ),
    ]);

    b.insertAll(db.launchConfigs, [
      LaunchConfigsCompanion.insert(
        id: 'cfg-llama-70b',
        name: 'llama-3.1-70b',
        description: const Value('Production 70B endpoint on the NVIDIA box.'),
        machineId: 'orion',
        program: 'vllm',
        command:
            'vllm serve meta-llama/Llama-3.1-70B-Instruct '
            '--tensor-parallel-size 2 --port 8001',
        workingDir: const Value('~/src/vllm'),
        port: 8001,
        envJson: Value(
          _env({'HF_HOME': '/mnt/models', 'CUDA_VISIBLE_DEVICES': '0,1'}),
        ),
      ),
      LaunchConfigsCompanion.insert(
        id: 'cfg-qwen-coder',
        name: 'qwen2.5-coder',
        description: const Value(
          'Coder model with prefill/decode disaggregation.',
        ),
        machineId: 'vega',
        program: 'llmd',
        command:
            'llm-d serve --model Qwen/Qwen2.5-Coder-32B-Instruct --port 8010',
        port: 8010,
      ),
      LaunchConfigsCompanion.insert(
        id: 'cfg-mixtral',
        name: 'mixtral-8×7b',
        description: const Value('MoE batch scoring job.'),
        machineId: 'orion',
        program: 'vllm',
        command:
            'vllm serve mistralai/Mixtral-8x7B-Instruct-v0.1 '
            '--tensor-parallel-size 2 --port 8002',
        port: 8002,
      ),
    ]);

    b.insertAll(db.jobs, [
      JobsCompanion.insert(
        id: 'job-llama-serve',
        name: 'llama-70b-serve',
        machineId: 'orion',
        program: 'vllm',
        command:
            'vllm serve meta-llama/Llama-3.1-70B-Instruct '
            '--tensor-parallel-size 2 --port 8001',
        workingDir: const Value('~/src/vllm'),
        port: 8001,
        status: JobStatus.running.name,
        pid: const Value(41517),
        startedAt: Value(now.subtract(const Duration(hours: 2, minutes: 14))),
        envJson: Value(
          _env({
            'HF_HOME': '/mnt/models',
            'CUDA_VISIBLE_DEVICES': '0,1',
            'VLLM_WORKER_MULTIPROC_METHOD': 'spawn',
          }),
        ),
      ),
      JobsCompanion.insert(
        id: 'job-qwen-eval',
        name: 'qwen-coder-eval',
        machineId: 'vega',
        program: 'llmd',
        command:
            'llm-d serve --model Qwen/Qwen2.5-Coder-32B-Instruct --port 8010',
        port: 8010,
        status: JobStatus.running.name,
        pid: const Value(39002),
        startedAt: Value(now.subtract(const Duration(minutes: 41))),
      ),
      JobsCompanion.insert(
        id: 'job-mixtral-batch',
        name: 'mixtral-batch',
        machineId: 'orion',
        program: 'vllm',
        command:
            'vllm serve mistralai/Mixtral-8x7B-Instruct-v0.1 '
            '--tensor-parallel-size 2 --port 8002',
        port: 8002,
        status: JobStatus.starting.name,
        pid: const Value(41902),
        startedAt: Value(now.subtract(const Duration(seconds: 9))),
      ),
      JobsCompanion.insert(
        id: 'job-deepseek-test',
        name: 'deepseek-v3-test',
        machineId: 'orion',
        program: 'vllm',
        command:
            'vllm serve deepseek-ai/DeepSeek-V3 '
            '--tensor-parallel-size 2 --port 8003',
        port: 8003,
        status: JobStatus.failed.name,
      ),
      JobsCompanion.insert(
        id: 'job-phi-profile',
        name: 'phi-4-profile',
        machineId: 'vega',
        program: 'llmd',
        command: 'llm-d serve --model microsoft/phi-4 --port 8020',
        port: 8020,
        status: JobStatus.exited.name,
      ),
    ]);
  });
}
