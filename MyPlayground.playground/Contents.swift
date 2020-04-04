import UIKit
import Foundation

//Quick sort
func quickSort(array:Array<Int>,low:Int,high:Int) -> Array<Int> {
    if low < high {
        let p = partrition(array: array,low: low,high: high)
        let arrayUpper = quickSort(array: p.0,low:low,high:p.1-1)
        let arrayLower = quickSort(array: arrayUpper,low:p.1+1,high:high)
        return arrayLower
    }

    return array
}

func partrition(array:Array<Int>,low:Int,high:Int) -> (Array<Int>,Int) {
    var mutableArray = array

    let pivot = mutableArray[high]
    var i = low - 1
    var j = low
    while high - 1 >= j {
        if mutableArray[j] < pivot {
            i = i + 1
            let temp = mutableArray[i]
            mutableArray[i] = mutableArray[j]
            mutableArray[j] = temp
        }
        j = j + 1
    }
    
    let temp = mutableArray[i + 1]
    mutableArray[i + 1] = mutableArray[high]
    mutableArray[high] = temp
    return (mutableArray,i + 1)
}

//Merge sort
func mergeSort(array:Array<Int>) -> Array<Int> {
    if array.count <= 1 { //based case
        return array
    }

    var left = Array<Int>()
    var right = Array<Int>()
    for (index,value) in array.enumerated() {
        if index < array.count/2 {
            left.append(value)
        }
        else {
            right.append(value)
        }
    }

    left = mergeSort(array: left)
    right = mergeSort(array: right)

    return merge(left: left, right: right)
}

func merge(left:Array<Int>, right: Array<Int>) -> Array<Int> {
    var result = Array<Int>()
    var mutableLeft = left
    var mutableRight = right

    // add smallest value from both left and right array
    while mutableLeft.count > 0 && mutableRight.count > 0 {
        if mutableLeft[0] < mutableRight[0] {
            result.append(mutableLeft[0])
            mutableLeft.remove(at: 0)
        }
        else {
            result.append(mutableRight[0])
            mutableRight.remove(at: 0)
        }
    }

    // add remaining value from left array
    while mutableLeft.count > 0 {
        result.append(mutableLeft[0])
        mutableLeft.remove(at: 0)
    }

    // add remaining value from right array
    while mutableRight.count > 0 {
        result.append(mutableRight[0])
        mutableRight.remove(at: 0)
    }

    return result
}

//Insertion sort
func insertionSort(array:Array<Int>) -> Array<Int> {
    if array.count <= 1 {
        return array
    }

    var mutableArray = array
    var i = 1
    while i < mutableArray.count {
        var j = i - 1
        var currentIndex = i
        while j >= 0 {
//            print(mutableArray, mutableArray[i], mutableArray[j], i, j)
            if mutableArray[j] > mutableArray[currentIndex] {
                let temp = mutableArray[j]
                mutableArray[j] = mutableArray[currentIndex]
                mutableArray[currentIndex] = temp
                currentIndex = j
            }

            j = j - 1
        }
        i = i + 1
    }
    return mutableArray
}

//Selection sort
func selectionSort(array:Array<Int>) -> Array<Int> {
    if array.count <= 1 {
        return array
    }

    var mutableArray = array
    var i = 0
    while i < mutableArray.count {
        var minIndex = i
        var j = i + 1
        while j < mutableArray.count {
            if mutableArray[j] < mutableArray[minIndex] {
                minIndex = j
            }
            j = j + 1
        }

        if minIndex != i {
            let temp = mutableArray[minIndex]
            mutableArray[minIndex] = mutableArray[i]
            mutableArray[i] = temp
        }

        i = i + 1
    }

    return mutableArray
}

//Bubble sort
func bubbleSort(array:Array<Int>) -> Array<Int> {
    if array.count <= 1 {
        return array
    }

    var mutableArray = array
    var swapped = true
    var checkedIndex = 0
    while swapped {
        swapped = false
        var i = 1
        while i < mutableArray.count - checkedIndex {
            if mutableArray[i - 1] > mutableArray[i] {
                let temp = mutableArray[i - 1]
                mutableArray[i - 1] = mutableArray[i]
                mutableArray[i] = temp
                swapped = true
            }
            i = i + 1
        }
        checkedIndex = checkedIndex + 1
    }

    return mutableArray
}

//Heap sort
/*
 get the count value
 convert the array to heap structure -> heapify to create a tree structure with highest value at root
 move the highest value to the end of the array
 create max heap again for the remaining items -> repeat till the end of the array
 
 */
func heapSort(array:Array<Int>) -> Array<Int> {
    var end = array.count - 1
    var mutableArray = heapify(array: array,end: end)

    while end > 0 {
        let temp = mutableArray[end]
        mutableArray[end] = mutableArray[0]
        mutableArray[0] = temp
        end = end - 1
        mutableArray = siftDown(array: mutableArray, start: 0, end: end)
        print("siftDown",mutableArray, end)
    }

    return mutableArray
}

func heapify(array:Array<Int>, end: Int) -> Array<Int> { //Build the heap in the array
    var start = floor(Double((end - 1)/2)) // iParent
    var mutableArray = array
    print("heapify",mutableArray, start)
    while start >= 0 {
        mutableArray = siftDown(array: mutableArray, start: Int(start), end: end)
        start = start - 1
        print("siftDown",mutableArray, start)
    }

    return mutableArray
}

func siftDown(array:Array<Int>, start: Int, end: Int) -> Array<Int>  { //Repair the heap whose root element is at index 'start', assuming the heaps rooted at its children are valid
    var mutableArray = array
    var root = start
    while 2*root + 1 <= end {
        let child = 2*root + 1
        var swap = root
        if mutableArray[swap] < mutableArray[child] {
            swap = child
            print("A",swap, root, child, end)
        }
        if child + 1 <= end && mutableArray[swap] < mutableArray[child + 1] {
            swap = child + 1
            print("B",swap, root, child, end)
        }
        if swap == root {
            break
        }
        else {
            let temp = mutableArray[root]
            mutableArray[root] = mutableArray[swap]
            mutableArray[swap] = temp
            root = swap
            print("C",swap, root, child, end)
        }
    }
    return mutableArray
}

//test code
let array = [6,4,2,1,5,8,7,9,3,0,11]

//quickSort(array: array,low: 0, high: array.count - 1)
//mergeSort(array: array)
//insertionSort(array: array)
//selectionSort(array: array)
//bubbleSort(array: array)
heapSort(array: array)

/*
 You are helping out with your school's "Queen of School" contest. You have the list of votes, where votes[i] is the name of the girl the ith person voted for. Your task is to find out who the winner is. If there are several girls who got the maximal number of votes, choose the winner by sorting the list of potential winners lexicographically and then choosing the last one.
 votes = ["Laura", "Emily", "Louise", "Natasha", "Emily", "Lilly", "Louise", "Laura", "Mary", "Mary"], the output should be
 queenOfSchool(votes) = "Mary".
 */
func isNameExistInDictionary(name: String, dictionaryNames: Dictionary<String, Int>) -> Bool {
    for existingName in dictionaryNames.keys {
        if (name == existingName) {
            return true
        }
    }
    return false
}
func queenOfSchool(array:Array<String>) -> String {
    var dictionaryNames = Dictionary<String, Int>()
    for (_,vote) in array.enumerated() {
        if (isNameExistInDictionary(name: vote, dictionaryNames: dictionaryNames)) {
            dictionaryNames[vote] = dictionaryNames[vote]! + 1
        }
        else {
            dictionaryNames[vote] = 1
        }
    }

    var result = "No one"
    var maxVotes = 0
    for key in dictionaryNames.keys {
        if maxVotes < dictionaryNames[key]! {
            maxVotes = dictionaryNames[key]!
            result = key
        }
        else if maxVotes == dictionaryNames[key]! {
            if key.compare(result) == .orderedDescending {
                result = key
            }
        }
    }

    return result
}
queenOfSchool(array: ["Laura", "Emily", "Louise", "Natasha", "Emily", "Lilly", "Louise", "Laura", "Mary", "Mary"])

/*
 You've noticed that the prices at your favorite retail store are sometimes different from the prices for the same items in the store's online shop. To determine how many items have different prices, you've decided to write a simple script.
 
 Given the physical store's item names retailItems and their prices retailPrices, as well as onlineItems and onlinePrices, return the number of items that have different prices in the store than they do online.
 
 Example
 
 For retailItems = ["tomato" , "bread", "salt"], retailPrices = [15.99, 4.99, 5.99], onlineItems = ["tomato" , "bread", "salt", "water"], and onlinePrices = [15.89, 4.99, 6, 1.99], the output should be
 pricesDiff(retailItems, retailPrices, onlineItems, onlinePrices) = 2;
 For retailItems = ["a", "b", "c", "d", "e"], retailPrices = [15.99, 4.99, 5.99, 1, 2], onlineItems = ["c" , "b", "d", "a", "f"], and onlinePrices = [5.99, 4.99, 1, 15.99, 4.5], the output should be
 pricesDiff(retailItems, retailPrices, onlineItems, onlinePrices) = 0.
 */
func pricesDiff(_ retailItems: [String], retailPrices: [Double], onlineItems: [String], onlinePrices: [Double]) -> Int {
    var result = 0
    if retailItems.count != retailPrices.count {
       return -1 // missing retail price or item
    }
    
    if onlineItems.count != onlinePrices.count {
        return -1 // missing online price or item
    }
    
    for (retailIndex, retailItem) in retailItems.enumerated() {
        for (onlineIndex, onlineItem) in onlineItems.enumerated() {
            if (retailItem == onlineItem) {
                if retailPrices[retailIndex] != onlinePrices[onlineIndex] {
                    result = result + 1
                }
                
                break
            }
        }
    }
    return result
}
var retailItems = ["a", "b", "c", "d", "e"]
var retailPrices = [15.99, 4.99, 5.99, 1, 2]
var onlineItems = ["c" , "b", "d", "a", "f"]
var onlinePrices = [5.99, 4.99, 1, 15.99, 4.5]
pricesDiff(retailItems, retailPrices: retailPrices, onlineItems: onlineItems, onlinePrices: onlinePrices)

retailItems = ["tomato" , "bread", "salt"]
retailPrices = [15.99, 4.99, 5.99]
onlineItems = ["tomato" , "bread", "salt", "water"]
onlinePrices = [15.89, 4.99, 6, 1.99]
pricesDiff(retailItems, retailPrices: retailPrices, onlineItems: onlineItems, onlinePrices: onlinePrices)
