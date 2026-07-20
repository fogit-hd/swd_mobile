/// Dịch nhãn checklist review (từ Excel template tiếng Anh của BE) sang tiếng Việt.
abstract final class ChecklistLabels {
  static String localize(String? raw) {
    if (raw == null) return '';
    final key = raw.trim();
    if (key.isEmpty) return key;
    return _lookup[key] ?? _lookup[_normalize(key)] ?? key;
  }

  static String? localizeNullable(String? raw) {
    if (raw == null) return null;
    final translated = localize(raw);
    return translated.isEmpty ? null : translated;
  }

  static String _normalize(String value) =>
      value.replaceAll(RegExp(r'\s+'), ' ').trim();

  static final Map<String, String> _lookup = () {
    final map = <String, String>{};
    for (final entry in _map.entries) {
      map[entry.key] = entry.value;
      map[_normalize(entry.key)] = entry.value;
    }
    return map;
  }();

  static const Map<String, String> _map = {
    // —— Review 1 sections ——
    'P1- Coverage of Objectives': 'P1 - Phạm vi mục tiêu',
    'P2-Practical applicability': 'P2 - Tính ứng dụng thực tế',
    'P3-Innovation and Creativity': 'P3 - Đổi mới và sáng tạo',
    'D1-URD-SRS-Overview': 'D1 - Tổng quan URD/SRS',
    'D1- Correctness': 'D1 - Tính đúng đắn',
    'D1- Quality attributes': 'D1 - Thuộc tính chất lượng',
    'D1- Special user requirements': 'D1 - Yêu cầu người dùng đặc thù',

    // —— Review 1 questions ——
    'Is problem to solve stated clearly?':
        'Vấn đề cần giải quyết đã được nêu rõ chưa?',
    'Is a functional overview of the system provided?':
        'Đã có tổng quan chức năng của hệ thống chưa?',
    'If assumptions that affect implementation have been made, are they stated?':
        'Nếu có giả định ảnh hưởng đến triển khai, đã được nêu rõ chưa?',
    'Is size of system (Usecase Points) larged enough for members to do  in project?':
        'Quy mô hệ thống (Use Case Points) có đủ lớn cho các thành viên thực hiện không?',
    'Does project have real users with real problems (pain/gain points)?':
        'Đồ án có người dùng thật với vấn đề thật (pain/gain) không?',
    'Does project  team work with real stakeholders ?':
        'Nhóm có làm việc với các bên liên quan thực tế không?',
    'Does project introduce new business model or localize successful global business models?':
        'Đồ án có giới thiệu mô hình kinh doanh mới hoặc địa phương hóa mô hình thành công toàn cầu không?',
    'Does project apply new technologies,algorithms or UI/UX (AR,VR,voice interaction?':
        'Đồ án có áp dụng công nghệ, thuật toán hoặc UI/UX mới (AR, VR, tương tác giọng nói) không?',
    'Do the requirements provide an adequate basis for design?':
        'Các yêu cầu có đủ cơ sở để thiết kế không?',
    'Is the implementation priority of each requirement included?':
        'Mỗi yêu cầu đã có mức ưu tiên triển khai chưa?',
    'Are algorithms intrinsic to the use-case defined?':
        'Các thuật toán gắn với use case đã được định nghĩa chưa?',
    'Is any necessary information missing from a requirement? If so, is it identified as to-be-determined marker':
        'Yêu cầu có thiếu thông tin cần thiết không? Nếu có, đã đánh dấu TBD chưa?',
    'Do any requirements conflict with or duplicate other requirements?':
        'Có yêu cầu nào xung đột hoặc trùng lặp với yêu cầu khác không?',
    'Is each requirement verifiable (such as by review, testing, demonstration, or analysis)?':
        'Mỗi yêu cầu có thể kiểm chứng được không (review, kiểm thử, demo, phân tích)?',
    'Is each requirement in scope for the project?':
        'Mỗi yêu cầu có nằm trong phạm vi đồ án không?',
    'Can all of the requirements be implemented within known constraints?':
        'Tất cả yêu cầu có thể triển khai trong các ràng buộc đã biết không?',
    'Are all performance objectives properly specified?':
        'Các mục tiêu hiệu năng đã được đặc tả đúng chưa?',
    'Are all security and safety considerations properly specified?':
        'Các yêu cầu bảo mật và an toàn đã được đặc tả đúng chưa?',
    'Are other pertinent quality attribute goals explicitly documented and quantified, with the acceptable trade-offs specified?':
        'Các mục tiêu chất lượng khác đã được ghi nhận, định lượng và nêu trade-off chấp nhận được chưa?',
    'Check whether interfaces with other systems are described':
        'Kiểm tra giao diện với hệ thống khác đã được mô tả chưa',
    'Check whether the required hardware is described':
        'Kiểm tra phần cứng yêu cầu đã được mô tả chưa',
    'Check whether specific software requirements are documented':
        'Kiểm tra yêu cầu phần mềm cụ thể đã được ghi nhận chưa',
    'Check whether networking Issues and connectivity requirements are documented':
        'Kiểm tra yêu cầu mạng và kết nối đã được ghi nhận chưa',
    'Check whether specific communication requirements are documented':
        'Kiểm tra yêu cầu truyền thông cụ thể đã được ghi nhận chưa',
    'Check whether availability requirements are documented':
        'Kiểm tra yêu cầu về tính sẵn sàng đã được ghi nhận chưa',
    'Multi Language support': 'Hỗ trợ đa ngôn ngữ',
    'Is any security required?': 'Có yêu cầu bảo mật nào không?',

    // —— Review 2 sections ——
    'D2-Architecture Design': 'D2 - Thiết kế kiến trúc',
    'D3- Detail Design': 'D3 - Thiết kế chi tiết',
    'P5-Technology choices for Software Architecture':
        'P5 - Lựa chọn công nghệ cho kiến trúc phần mềm',
    'P6- Application of computing knowledge for Implementation':
        'P6 - Ứng dụng kiến thức tin học khi triển khai',
    'P7-Complexity of algorithm/ internal processing':
        'P7 - Độ phức tạp thuật toán / xử lý nội bộ',

    // —— Review 2 questions ——
    'Are the system architecture (sub-systems and connection between theme) described in deployment view and process view? (Check system overview diagram )':
        'Kiến trúc hệ thống (subsystem và kết nối) đã mô tả ở góc nhìn triển khai và tiến trình chưa? (Kiểm tra sơ đồ tổng quan)',
    'Has the dataflow among all sub-systems been described? (Check activity diagrams/Flowcharts)':
        'Luồng dữ liệu giữa các subsystem đã được mô tả chưa? (Kiểm tra activity/flowchart)',
    'Does the architecture cleanly decompose the top-level elements of the system? (Check package diagram and component diagrams)':
        'Kiến trúc đã phân rã rõ các thành phần cấp cao chưa? (Kiểm tra package/component diagram)',
    'Have all shared data and resource between components been described? (Check API endpoints )':
        'Dữ liệu và tài nguyên dùng chung giữa các component đã được mô tả chưa? (Kiểm tra API)',
    'Does the Logical Design (ERD) depicts relation between all entities in system? (Check entity, entity relationship, attributes of entity)':
        'Thiết kế logic (ERD) đã thể hiện quan hệ giữa mọi thực thể chưa?',
    'Does the Physical Design (Database) reprensent the materialization of a databasen into system? (Check tables, fields , size and type of fields, default values and mapping with logical design )':
        'Thiết kế vật lý (CSDL) đã phản ánh đúng ánh xạ sang hệ thống chưa? (bảng, trường, kiểu, mặc định, mapping)',
    'Does the screen design consistent, aesthetically and easy to use ? (Check  Screen, UI component in each screen (type, required , format ..), screen flows (screen structure and transition between screens) )':
        'Thiết kế màn hình có nhất quán, thẩm mỹ và dễ dùng không? (UI, luồng màn hình)',
    'Does the class design for each unit contain appropriate views (e.g., static structure, data definition, data flow, control flow, states, etc.), has the overall function and intent of each unit? (Check class diagram )':
        'Thiết kế lớp cho từng đơn vị có đủ góc nhìn phù hợp và thể hiện chức năng/ý định chưa? (class diagram)',
    'Are the main entity models sufficient to capture all states and behavior? (Check state diagram of important entities in system)':
        'Mô hình thực thể chính có đủ để nắm trạng thái và hành vi không? (state diagram)',
    'Does the project use reasonable use of external services (3rd services- API)?':
        'Đồ án sử dụng dịch vụ bên thứ ba (API) một cách hợp lý chưa?',
    'Does the project use up-to-date Frontend technology with good design pattern (Angular,ReactJs, VueJs Jquery ,Typescript..)?':
        'Đồ án dùng công nghệ Frontend cập nhật với design pattern phù hợp chưa?',
    'Does the project use up-to-date Backend technology with good design (RestApi, grpc, GraphQl ..)':
        'Đồ án dùng công nghệ Backend cập nhật với thiết kế tốt chưa? (REST, gRPC, GraphQL…)',
    'Does the project use up-to-date Mobile technology? (Flutter, Swift iOS … )':
        'Đồ án dùng công nghệ Mobile cập nhật chưa? (Flutter, Swift iOS…)',
    'Does source code follow coding convention ?':
        'Mã nguồn có tuân thủ coding convention không?',
    'Does project team understand and apply programming techniques: OOP, SOLID principles?':
        'Nhóm có hiểu và áp dụng OOP, nguyên lý SOLID không?',
    'Appropriate using config file (connection string, access token), enumeration...':
        'Sử dụng hợp lý file cấu hình (connection string, token), enumeration…',
    'Does project apply design pattern for source code?':
        'Đồ án có áp dụng design pattern trong mã nguồn không?',
    'Does database follow standard? (Check naming convention, key , foreign keys)':
        'CSDL có tuân thủ chuẩn không? (đặt tên, khóa, khóa ngoại)',
    'Does project correctly state the problem to be solved?':
        'Đồ án nêu đúng vấn đề cần giải quyết chưa?',
    'Does project choose the right algorithm to solve the problem?':
        'Đồ án chọn thuật toán phù hợp để giải quyết vấn đề chưa?',
    'Does project use the right libraries / source code / services available  to solve the problem?':
        'Đồ án dùng thư viện / mã nguồn / dịch vụ phù hợp chưa?',
    'Does project implement and enhance existing solutions for better result?':
        'Đồ án có triển khai và cải tiến giải pháp sẵn có để kết quả tốt hơn không?',

    // —— Review 3 names ——
    'Scope: Coverage of objectives': 'Phạm vi: Bao phủ mục tiêu',
    'Practical applicability': 'Tính ứng dụng thực tế',
    'Innovation and Creativity': 'Đổi mới và sáng tạo',
    'UI/UX': 'UI/UX',
    'Technology choices for Software Architecture':
        'Lựa chọn công nghệ cho kiến trúc phần mềm',
    'Application of computing knowledge for Implementation':
        'Ứng dụng kiến thức tin học khi triển khai',
    'Complexity of algorithm/ internal processing':
        'Độ phức tạp thuật toán / xử lý nội bộ',
    'Technology choices for Deployment & Maintenance':
        'Lựa chọn công nghệ cho triển khai & bảo trì',
    'User requirement and System Requirment':
        'Yêu cầu người dùng và yêu cầu hệ thống',
    'Architecture Design Document': 'Tài liệu thiết kế kiến trúc',
    'Detail Design Document': 'Tài liệu thiết kế chi tiết',
    'Testing Document': 'Tài liệu kiểm thử',
    'System Deployment and Delivery Package':
        'Triển khai hệ thống và gói bàn giao',
  };
}
