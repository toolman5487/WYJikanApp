//
//  PeoplePositionFormatting.swift
//  WYJikanApp
//

import Foundation

nonisolated enum PeoplePositionFormatting {

    static func localizedName(for rawValue: String?) -> String? {
        guard let rawValue = DisplayTextFormatting.nonEmpty(rawValue) else {
            return nil
        }

        switch rawValue.lowercased() {
        case "producer":
            return "製作人"
        case "executive producer":
            return "執行製作人"
        case "director":
            return "導演"
        case "chief director":
            return "總導演"
        case "assistant director":
            return "助理導演"
        case "episode director":
            return "單集導演"
        case "storyboard":
            return "分鏡"
        case "script":
            return "劇本"
        case "series composition":
            return "系列構成"
        case "original creator":
            return "原作"
        case "original character design":
            return "角色原案"
        case "character design":
            return "角色設計"
        case "chief animation director":
            return "總作畫監督"
        case "animation director":
            return "作畫監督"
        case "key animation":
            return "原畫"
        case "second key animation":
            return "第二原畫"
        case "in-between animation":
            return "動畫"
        case "music":
            return "音樂"
        case "sound director":
            return "音響監督"
        case "sound effects":
            return "音效"
        case "theme song performance":
            return "主題曲演唱"
        case "theme song composition":
            return "主題曲作曲"
        case "theme song lyrics":
            return "主題曲作詞"
        case "theme song arrangement":
            return "主題曲編曲"
        case "art director":
            return "美術監督"
        case "background art":
            return "背景美術"
        case "director of photography":
            return "攝影監督"
        case "editing":
            return "剪輯"
        case "mechanical design":
            return "機械設計"
        case "color design":
            return "色彩設計"
        case "planning":
            return "企劃"
        case "production assistant":
            return "製作助理"
        case "setting":
            return "設定"
        case "story & art":
            return "故事與作畫"
        case "story":
            return "故事"
        case "art":
            return "作畫"
        default:
            return rawValue
        }
    }
}
