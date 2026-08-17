import 'package:centrode/features/graph/store/in_memory_graph_api.dart';
import '../../../shared/contract_suites/graph_api_contract_suite.dart';

void main() {
  runGraphApiContractTests('InMemoryGraphApi', () => InMemoryGraphApi());
}
