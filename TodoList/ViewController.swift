//
//  ViewController.swift
//  TodoList
//
//  Created by Yongwoo Yoo on 2022/02/24.
//

import UIKit

class ViewController: UIViewController {
	@IBOutlet weak var tableView: UITableView!
	@IBOutlet var editButton: UIBarButtonItem! //Strong으로 선언. weak면 done버튼을 눌렀을시 메모리에서 해제가 되어 재사용불가
	var doneButton: UIBarButtonItem?
	
	var tasks = [Task]() { // Task 타입의 배열 선언
		didSet { //프로퍼티 옵저버. set 될때마다 호출됨
			self.saveTasks()
		}
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		self.doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action:#selector(doneButtonTab) ) //버튼을 선택하였을때의 메소드
		self.tableView.dataSource = self //UITableViewDataSource
		self.tableView.delegate = self //UITableViewDelegate
		self.loadTasks()
	}

	//done버튼 선택시 호출되는 method. selector 타입은 @objc가 필수
	@objc func doneButtonTab() {
		self.navigationItem.leftBarButtonItem = self.editButton //done버튼을 edit버튼으로 변경
		self.tableView.setEditing(false, animated: true) //편집모드 끄기
	}

	@IBAction func tabEditButton(_ sender: UIBarButtonItem) {
		guard !self.tasks.isEmpty else { return }
		self.navigationItem.leftBarButtonItem = self.doneButton //edit버튼을 done버튼으로 변경
		self.tableView.setEditing(true, animated: true) //편집모드 켜기
	}
	
	@IBAction func tabAddButton(_ sender: UIBarButtonItem) {
		let alert = UIAlertController(title: "할 일 등록", message: nil, preferredStyle: .alert)
		let registerButton = UIAlertAction(title: "등록", style: .default, handler: { [weak self] _ in
			guard let title = alert.textFields?[0].text else { return }
			let task = Task(title: title, done: false)
			self?.tasks.append(task)
			self?.tableView.reloadData()
		})
		let cancelButton = UIAlertAction(title: "취소", style: .cancel, handler: nil)
		alert.addAction(cancelButton)
		alert.addAction(registerButton)
		alert.addTextField(configurationHandler: {textField in
			textField.placeholder = "할 일을 입력해주세요."
		}) //표시하기전 구성하는 클로저
		self.present(alert, animated: true, completion: nil)
	}
	
//	let array = [1,2,3,4,5]
//	array.map {
//		$0 + 1
//	}
// [2, 3, 4, 5, 6]
	func saveTasks() {
		//배열에 있는 요소들을 >> dictionary로 저장
		let data = self.tasks.map { //map형태로 배열요소들을 dictionary에 매핑
			[
				"title": $0.title,
				"done": $0.done
			]
		}
		let userDefaults = UserDefaults.standard //싱글톤. 1개의 인스턴스만 존재
		userDefaults.set(data, forKey: "tasks") //tasks키로 저장
	}

	func loadTasks() {
		let userDefaults = UserDefaults.standard
		guard let data = userDefaults.object(forKey: "tasks") as? [[String: Any]] else { return } //tasks키로 불러옴. object는 리턴이 Any타입이기때문에 dictionary 배열 형태로 타입캐스팅
		self.tasks = data.compactMap {
			guard let title = $0["title"] as? String else { return nil }
			guard let done = $0["done"] as? Bool else { return nil }
			return Task(title: title, done: done)
		}
	}


	
}

extension ViewController: UITableViewDataSource { //데이터를 받아 뷰를 그려주는 delegate
	//각 세션에 표시할 행의 갯수를 묻는 메소드
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return self.tasks.count
	}

	//구성후 리턴시 cell의 데이터 반환
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		//스토리보드에 정의한 셀을 가져옴
		//dequeueReusableCell 지정된 재사용 식별자 셀 객체를 반환
		let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) //"Cell"은 스토리보드에서 정의
		let task = self.tasks[indexPath.row]
		cell.textLabel?.text = task.title
		
		//완료 상태에 따른 체크마크 표시여부
		if task.done {
			cell.accessoryType = .checkmark
		} else {
			cell.accessoryType = .none
		}
		return cell
	}
	
	//commit forRowAt : 편집모드에서 삭제버튼이 눌린셀이 어떤셀인지 알려주는 메소드
	func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
		self.tasks.remove(at: indexPath.row)
		tableView.deleteRows(at: [indexPath], with: .automatic) //편집모드나 swipe모드로 삭제가 가능해짐

		//비어있으면 강제 done
		if self.tasks.isEmpty {
			self.doneButtonTab()
		}
	}
	
	//편집여부에서 셀 이동가능여부 설정
	func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
		return true
	}
	
	//moveRowAt 셀이 재정렬 된 이후 호출
	func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
		//배열 재정렬
		var tasks = self.tasks
		let task = tasks[sourceIndexPath.row]
		tasks.remove(at: sourceIndexPath.row)
		tasks.insert(task, at: destinationIndexPath.row)
		self.tasks = tasks
	}
}

extension ViewController: UITableViewDelegate { //테이블뷰의 외관담당
	//셀이 선택되었을때 어떤 셀이 선택되었는지 알려주는 delegate
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		var task = self.tasks[indexPath.row] //선택된 행의번호
		task.done = !task.done //true --> false,   false --> true를 저장
		self.tasks[indexPath.row] = task //변경된 정보를 현재 로우에 다시덮어씌움
		self.tableView.reloadRows(at: [indexPath], with: .automatic) //선택된 행만 reload, 애니메이션은 auto
	}
}
