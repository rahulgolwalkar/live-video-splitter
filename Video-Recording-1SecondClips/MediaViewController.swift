//
//  MediaViewController.swift
//  LiveVideoSplitter2
//
//  Created by rahulg on 06/05/18.
//  Copyright © 2018 rahulg. All rights reserved.
// 

import UIKit

class MediaViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    var dirArray = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        dirArray = getAllDirs().sorted{ $0 > $1}
        
        tableView.reloadData()
    }
    
    func getAllDirs() -> [String] {
        var dirs = [String]()
        do {
            dirs = try FileManager.default.contentsOfDirectory(atPath: FileManager.documentsDir())
        } catch {
            print(error)
        }
        return dirs
    }
}

extension MediaViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dirArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: FolderTableViewCell = tableView.dequeueReusableCell(withIdentifier: "FolderTableViewCell", for: indexPath) as! FolderTableViewCell
        cell.textLabel?.text = dirArray[indexPath.row]
        return cell
    }
    
    
}

extension MediaViewController: UITableViewDelegate {
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if segue.identifier == "mediatofilevc" {
            let destVC: FilesTableViewController = segue.destination as! FilesTableViewController
            let indexPath  = self.tableView.indexPathForSelectedRow
            destVC.folderName = dirArray[(indexPath?.row)!]
        }
        
    }

}
